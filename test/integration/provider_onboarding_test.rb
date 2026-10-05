require "test_helper"
class ProviderOnboardingTest < ActionDispatch::IntegrationTest
  setup do
    build_catalog
    login_admin
  end

  test "a provider is onboarded stage by stage and cannot be published until every stage is complete" do
    get new_admin_provider_path
    assert_response :success
    assert_select ".stepper-step", 6
    assert_select ".stepper-step.open .stepper-step-copy strong", "Organisation"
    assert_select ".lookup-note strong", /CAC business register is not connected/

    post admin_providers_path, params: { provider: {
      legal_name: "Northgate Surgical Limited", registration_number: "9001234", registration_status: "Active",
      name: "Northgate Clinic", provider_type: "Day surgery centre", phone: "+2348099887766", email: "hello@northgate.test"
    } }
    provider = Provider.find_by!(registration_number: "9001234")
    assert_redirected_to stage_admin_provider_path(provider, stage: "organisation")
    assert_not provider.published?, "a new provider starts as a draft"

    # The rail opens on the stage that owns the next step, and says what that step is.
    get stage_admin_provider_path(provider, stage: "organisation")
    assert_select ".stepper-step.done .stepper-step-copy strong", "Organisation"
    assert_select ".stepper-step.current .stepper-step-copy strong", "Locations"
    assert_select ".stepper-now p", /Add at least one location/

    post publish_admin_provider_path(provider)
    assert_response :unprocessable_entity
    assert_not provider.reload.published?

    post locations_admin_provider_path(provider), params: { provider_location: { name: "Yaba", address_line: "5 Herbert Macaulay Way", city: "Yaba", state: "Lagos", country: "Nigeria" } }
    assert_redirected_to stage_admin_provider_path(provider, stage: "locations")
    assert_equal "Yaba, Lagos", provider.reload.location, "the public display location follows the first location"

    patch stage_admin_provider_path(provider, stage: "services"), params: {
      provider: { booking_process: "ora_coordinates", consultation_fee: 50_000, modes: [ "in_person" ] },
      services: { @procedure.id.to_s => { offered: "1", price: "620000", consultation_fee: "50000", status: "active" } }
    }
    assert_redirected_to stage_admin_provider_path(provider, stage: "services")
    assert_equal 620_000, provider.listings.sole.price
    assert_equal "in_person", provider.reload.consultation_modes
  end

  test "a manual verification has to record its evidence, and the check is not saved without it" do
    provider = Provider.create!(name: "Evidence Clinic", slug: "evidence-clinic", published: false)
    post checks_admin_provider_path(provider), params: { kind: "facility", check: { status: "verified", source: "manual", evidence: "" } }
    assert_response :unprocessable_entity
    assert_empty provider.provider_verifications.reload, "a rejected check is never persisted"
    assert_select ".check-row.verified", 0, "and it must not read back as verified"

    post checks_admin_provider_path(provider), params: { kind: "facility", check: { status: "verified", source: "manual", reference: "LSHSC/2024/0914", evidence: "Licence reviewed during the onboarding visit." } }
    assert_redirected_to stage_admin_provider_path(provider, stage: "verification")
    check = provider.provider_verifications.reload.sole
    assert check.verified?
    assert_equal @admin, check.verified_by
  end

  test "a procedure a care journey depends on cannot be dropped from the provider that offers it" do
    care = @patient.care_cases.create!(listing: @listing)
    patch stage_admin_provider_path(@provider, stage: "services"), params: { services: { @procedure.id.to_s => { offered: "0" } } }
    assert_response :unprocessable_entity
    assert Listing.exists?(care.listing_id)
    assert_select ".form-errors", /cannot be removed while care journeys reference them/
  end

  test "the procedure catalogue is read-only about who offers a procedure" do
    get admin_edit_catalog_path(kind: "procedures", id: @procedure.id)
    assert_response :success
    assert_select "h2", text: "Offered by"
    assert_select "a[href=?]", stage_admin_provider_path(@provider, stage: "services")
    assert_select "a", text: /Add price/, count: 0
    [ admin_catalog_path("providers"), admin_catalog_path("listings") ].each do |gone|
      get gone
      assert_response :not_found
    end
  end
end
