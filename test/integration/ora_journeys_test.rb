require "test_helper"
class OraJourneysTest < ActionDispatch::IntegrationTest
  setup { build_catalog }
  test "public pages render and catalog filters work with Turbo frames" do
    [ root_path, procedures_path, procedure_path(@procedure), providers_path, provider_path(@provider), affordability_path, how_path, mobile_path, privacy_path, support_path, sign_in_path, admin_sign_in_path ].each do |path|
      get path
      assert_response :success, "Failed to render #{path}"
    end
    get procedures_path(category: "Vision"), headers: { "Turbo-Frame" => "procedure_results" }
    assert_response :success
    assert_select "turbo-frame#procedure_results", 1
    assert_select ".procedure-card", 0
    get procedures_path(category: "Dental", q: "Test")
    assert_select ".procedure-card", 1
    get affordability_path(budget: 10000, term: 6)
    assert_select ".procedure-card", 0
    get admin_root_path
    assert_redirected_to admin_sign_in_path
    get my_care_path
    assert_redirected_to sign_in_path
  end
  test "OTP is single-use and users cannot access another patient care" do
    login_patient
    get my_care_path
    assert_response :success
    other = User.create!(phone: "+2348099990033", first_name: "Other")
    care = other.care_cases.create!(listing: @listing)
    get case_path(care)
    assert_response :not_found
    post cancel_case_path(care)
    assert_response :not_found
    assert_equal "new", care.reload.status
    assert_nil @patient.reload.otp_digest
    post verify_path, params: { code: "000000" }
    assert_redirected_to verify_path
  end
  test "expired codes do not authenticate and customer login cannot access admin accounts" do
    post sign_in_path, params: { phone: @patient.phone, first_name: "Test" }
    follow_redirect!
    code = Nokogiri::HTML(response.body).at_css(".demo-code strong").text
    @patient.update!(otp_expires_at: 1.minute.ago)
    post verify_path, params: { code: code }
    assert_redirected_to verify_path
    get my_care_path
    assert_redirected_to sign_in_path
    post sign_in_path, params: { phone: @admin.phone, first_name: "Admin" }
    assert_redirected_to sign_in_path
    assert_nil @admin.reload.otp_digest
  end
  test "financing journey from intake through consultation offer acceptance funding and treatment" do
    login_patient
    get start_journey_path(listing_id: @listing.id)
    follow_redirect!
    assert_response :success
    post journey_path("consent"), params: { consent: "1" }
    assert_redirected_to journey_path("personal")
    assert_no_difference "CareCase.count" do
      post journey_path("personal"), params: { date_of_birth: 10.years.ago.to_date, area: "Lagos" }
      assert_response :unprocessable_entity
    end
    post journey_path("personal"), params: { date_of_birth: "1993-01-01", area: "Lagos" }
    assert_redirected_to journey_path("employment")
    get journey_path("employment")
    assert_response :success
    post journey_path("employment"), params: { employment: "Employed", monthly_income: 750000 }
    get journey_path("budget")
    assert_response :success
    post journey_path("budget"), params: { monthly_budget: 75000 }
    get journey_path("consent")
    assert_response :success
    assert_difference "CareCase.count", 1 do
      post journey_path("consent"), params: { consent: "1" }
    end
    follow_redirect!
    assert_response :success
    care = @patient.care_cases.last
    assert_equal "pending", care.financing_status
    assert_no_difference "CareCase.count" do
      post journey_path("consent"), params: { consent: "1" }
    end
    get consultation_case_path(care)
    assert_response :success
    post book_consultation_case_path(care), params: { date: Date.yesterday.to_s, time: "11:00", mode: "in_person" }
    assert_nil care.reload.consultation_at
    post book_consultation_case_path(care), params: { date: next_weekday.to_s, time: "11:00", mode: "in_person" }
    assert_equal "consultation_booked", care.reload.status
    get case_path(care)
    assert_response :success
    get plan_case_path(care)
    assert_response :success
    post accept_terms_case_path(care), params: { consent: "1" }
    assert_nil care.reload.terms_accepted_at
    post book_treatment_case_path(care), params: { date: next_weekday.to_s, time: "14:00" }
    assert_nil care.reload.treatment_at
    operations = open_session
    login_admin(operations)
    [ admin_root_path, admin_cases_path, admin_case_path(care), admin_catalog_path("procedures"), admin_new_catalog_path("procedures"), admin_edit_catalog_path(kind: "procedures", id: @procedure.id), admin_providers_path, new_admin_provider_path, admin_appointments_path, admin_inbox_path ].each do |path|
      operations.get path
      assert_equal 200, operations.response.status, "Failed to render #{path}"
    end
    operations.patch admin_case_path(care), params: { care_case: { medical_status: "approved", final_price: 650000, approved_amount: 650000, lender_name: "Demo lender", monthly_payment: 60000, term_months: 12, financing_terms: "Demo terms only. Total repayable 720000. No actual agreement.", financing_status: "offered", status: "treatment_plan", internal_notes: "PRIVATE_TEST_NOTE" } }
    assert_equal 302, operations.response.status
    assert care.reload.ready_for_terms?
    get plan_case_path(care)
    assert_response :success
    assert_select 'input[value="Record demo acceptance →"]', 1
    get case_path(care)
    assert_no_match "PRIVATE_TEST_NOTE", response.body
    post accept_terms_case_path(care), params: { consent: "1" }
    assert_equal "accepted", care.reload.financing_status
    operations.patch admin_case_path(care), params: { care_case: { financing_status: "funded", status: "funded" } }
    assert_equal 302, operations.response.status
    assert care.reload.ready_to_book?
    post cancel_case_path(care)
    assert_equal "funded", care.reload.status
    post book_treatment_case_path(care), params: { date: next_weekday.to_s, time: "14:00" }
    assert_equal "treatment_booked", care.reload.status
    travel_to 10.days.from_now do
      login_admin(operations) # Sessions expire after eight hours.
      operations.patch admin_case_path(care), params: { care_case: { status: "completed", treatment_confirmed: true } }
      assert_equal 302, operations.response.status
      assert_equal "completed", care.reload.status
      login_patient
      post review_case_path(care), params: { rating: 5, review: "A thoughtful experience." }
      assert_equal 5, care.reload.rating
    end
  end
  test "the single start entry lets the patient choose how to pay on the first step" do
    login_patient
    get start_journey_path(listing_id: @listing.id)
    post journey_path("personal"), params: { date_of_birth: "1993-01-01", area: "Lagos", mode: "self_pay" }
    assert_redirected_to journey_path("consent")
    post journey_path("personal"), params: { date_of_birth: "1993-01-01", area: "Lagos", mode: "finance" }
    assert_redirected_to journey_path("employment")
  end
  test "self-pay bypasses financial intake and saved care waitlist support and catalog persist" do
    login_patient
    post save_procedure_path(@procedure)
    assert_equal 1, @patient.saved_procedures.count
    post save_procedure_path(@procedure)
    assert_equal 0, @patient.saved_procedures.count
    get start_journey_path(listing_id: @listing.id, mode: "self_pay")
    post journey_path("personal"), params: { date_of_birth: "1993-01-01", area: "Lagos" }
    assert_redirected_to journey_path("consent")
    post journey_path("consent"), params: { consent: "1" }
    care = @patient.care_cases.last
    assert_not care.financing_requested?
    assert_equal "not_requested", care.financing_status
    post waitlist_path, params: { email: "new@example.test" }
    post waitlist_path, params: { email: "NEW@example.test" }
    assert_equal 1, WaitlistEntry.count
    post support_path, params: { support_request: { email: "test@example.test", message: "A question about planned care." } }
    assert_equal 1, SupportRequest.count
    admin = open_session
    login_admin(admin)
    admin.post admin_catalog_path("procedures"), params: { record: { name: "Another care option", category: "Vision", starting_price: 90000, summary: "A new test procedure.", published: true } }
    assert_equal 302, admin.response.status
    assert Procedure.exists?(slug: "another-care-option")
    @provider.update!(published: false)
    get provider_path(@provider)
    assert_response :not_found
    admin.patch admin_resolve_path(SupportRequest.last)
    assert_equal "resolved", SupportRequest.last.status
  end
  test "operations price revisions require fresh patient acceptance and funded terms are immutable" do
    care = @patient.care_cases.create!(listing: @listing, financing_requested: true, medical_status: "approved", final_price: 600000, approved_amount: 600000, monthly_payment: 56000, lender_name: "Demo lender", financing_terms: "Demo terms", financing_status: "accepted", terms_accepted_at: Time.current)
    login_admin
    patch admin_case_path(care), params: { care_case: { final_price: 650000 } }
    assert_redirected_to admin_case_path(care)
    assert_nil care.reload.terms_accepted_at
    assert_equal "pending", care.financing_status
    assert_equal 650000, care.final_price
    care.update!(approved_amount: 650000, financing_status: "funded", terms_accepted_at: Time.current)
    patch admin_case_path(care), params: { care_case: { final_price: 700000 } }
    assert_response :unprocessable_entity
    assert_equal 650000, care.reload.final_price
  end
  test "the care journey opens on the phase that owns the next step and saves one phase at a time" do
    care = @patient.care_cases.create!(listing: @listing, status: "consultation_booked", consultation_at: next_weekday.to_time + 11.hours, financing_requested: true)
    login_admin
    get admin_case_path(care)
    assert_response :success
    assert_select ".admin-sidebar nav > a", 7
    assert_select ".stepper-step.open .stepper-step-copy strong", "Consultation"
    assert_select ".stepper-step.current .stepper-step-copy strong", "Consultation"
    assert_select ".stepper-now p", /Record the clinic's confirmation/
    get admin_case_path(care, section: "financing")
    assert_select ".stepper-step.open .stepper-step-copy strong", "Financing"
    assert_select ".stepper-step.current .stepper-step-copy strong", "Consultation"
    patch admin_case_path(care), params: { section: "consultation", care_case: { status: "consultation_booked", consultation_confirmed: "1" } }
    assert_redirected_to admin_case_path(care, section: "consultation")
    assert care.reload.consultation_confirmed?
    assert_equal "pending", care.medical_status
    get admin_appointments_path
    assert_response :success
    assert_select ".appointment-when strong", care.consultation_at.strftime("%d %b %Y")
    get admin_edit_catalog_path(kind: "procedures", id: @procedure.id)
    assert_select "h2", text: "Offered by"
    assert_select ".data-table td strong", text: @provider.name
  end
end
