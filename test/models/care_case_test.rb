require "test_helper"
class CareCaseTest < ActiveSupport::TestCase
  setup { build_catalog }
  test "funding cannot bypass approval and patient acceptance" do
    care = @patient.care_cases.create!(listing: @listing, financing_requested: true)
    assert_not care.update(financing_status: "funded")
    assert_includes care.errors.full_messages.join, "Medical approval"
    care.reload.assign_attributes(medical_status: "approved", final_price: 600000, approved_amount: 600000, monthly_payment: 56000, lender_name: "Demo partner", financing_terms: "Example terms", financing_status: "offered")
    assert care.save
    assert care.ready_for_terms?
    assert_not care.update(financing_status: "funded")
    assert_includes care.errors.full_messages.join, "patient must accept"
  end
  test "price gap blocks acceptance and completion before date is rejected" do
    care = @patient.care_cases.create!(listing: @listing, financing_requested: true, medical_status: "approved", final_price: 700000, approved_amount: 600000, monthly_payment: 56000, lender_name: "Demo partner", financing_terms: "Example terms", financing_status: "offered")
    assert_equal 100000, care.funding_gap
    assert_not care.ready_for_terms?
    assert_not care.update(financing_status: "accepted", terms_accepted_at: Time.current)
    care.reload.update!(financing_requested: false, financing_status: "not_requested")
    assert_not care.update(status: "completed", treatment_at: 1.day.from_now)
  end
  test "upfront contributions cover a price gap but receipt is needed before treatment" do
    care = @patient.care_cases.create!(listing: @listing, financing_requested: true, medical_status: "approved", final_price: 700000, approved_amount: 600000, upfront_amount: 100000, monthly_payment: 56000, lender_name: "Demo partner", financing_terms: "Example terms", financing_status: "offered")
    assert_equal 0, care.funding_gap
    assert care.ready_for_terms?
    care.update!(financing_status: "accepted", terms_accepted_at: Time.current)
    care.update!(financing_status: "funded")
    assert_not care.ready_to_book?
    care.update!(upfront_confirmed: true)
    assert care.ready_to_book?
    assert_not care.update(treatment_confirmed: true)
  end
end
