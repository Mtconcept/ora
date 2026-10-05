ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
class ActiveSupport::TestCase
  def build_catalog
    @procedure = Procedure.create!(name: "Test dental care", slug: "test-dental-care", category: "Dental", starting_price: 600000, summary: "A test possibility.", description: "Discuss your options with a clinician.")
    @provider = Provider.create!(name: "Test clinic", slug: "test-clinic", location: "Lagos", specialty: "Dental", years_practicing: 10)
    @listing = Listing.create!(procedure: @procedure, provider: @provider, price: 600000)
    @patient = User.create!(first_name: "Test", last_name: "Patient", phone: "+2348099990001", email: "patient@example.test")
    @admin = User.create!(first_name: "Test", phone: "+2348099990002", email: "admin@example.test", role: "super_admin", status: "active", admin: true, password: "TestPassword2026!")
  end
  def next_weekday
    day = Date.current + 3
    day += 1 while day.saturday? || day.sunday?
    day
  end
end
class ActionDispatch::IntegrationTest
  def login_patient(client = self)
    client.post sign_in_path, params: { first_name: "Test", last_name: "Patient", phone: @patient.phone, email: @patient.email }
    client.follow_redirect!
    code = Nokogiri::HTML(client.response.body).at_css(".demo-code strong")&.text
    assert code.present?, "Expected a development-only OTP"
    client.post verify_path, params: { code: code }
    code
  end
  def login_admin(client = self)
    client.post admin_sign_in_path, params: { email: @admin.email, password: "TestPassword2026!" }
  end
end
