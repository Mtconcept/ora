require "test_helper"

class AdminUserManagementTest < ActionDispatch::IntegrationTest
  setup do
    build_catalog
    login_admin
  end

  test "admin can search, inspect, suspend, and reactivate a user with an audit trail" do
    get admin_users_path(q: @patient.email)
    assert_response :success
    assert_select "h1", "Users"
    assert_select "td", text: @patient.email

    post suspend_admin_user_path(@patient)
    assert_redirected_to admin_user_path(@patient)
    assert_equal "suspended", @patient.reload.status
    assert_equal "user_suspended", AdminAuditEvent.last.action

    post reactivate_admin_user_path(@patient)
    assert_redirected_to admin_user_path(@patient)
    assert_equal "active", @patient.reload.status
    assert_equal "user_reactivated", AdminAuditEvent.last.action
  end

  test "admin can create a team member and settings lists the team" do
    assert_difference [ "User.count", "AdminAuditEvent.count" ], 1 do
      post admin_users_path, params: { user: {
        first_name: "Nia", last_name: "Cole", email: "nia@example.test", phone: "+2348099990012",
        role: "admin", status: "active", password: "SecurePassword2026!", password_confirmation: "SecurePassword2026!"
      } }
    end
    created = User.find_by!(email: "nia@example.test")
    assert created.staff?

    get admin_settings_team_path
    assert_response :success
    assert_select "h1", "Team management"
    assert_select "td", text: "nia@example.test"
  end

  test "admin cannot create a patient account" do
    assert_no_difference [ "User.count", "AdminAuditEvent.count" ] do
      post admin_users_path, params: { user: {
        first_name: "New", last_name: "Patient", email: "new-patient@example.test", phone: "+2348099990088",
        role: "customer", status: "active"
      } }
    end
    assert_response :unprocessable_entity
    assert_select ".form-errors", text: /patient accounts are created by patients/

    get new_admin_user_path
    assert_response :success
    assert_select "select#user_role option[value='customer']", count: 0
    assert_select "h1", "Add team member"
  end

  test "customers combines registered people, inquiries, and waitlist contacts" do
    SupportRequest.create!(email: "question@example.test", message: "I would like to understand the process.", status: "open")
    WaitlistEntry.create!(email: "mobile@example.test")

    get admin_customers_path
    assert_response :success
    assert_select "h1", "Patients"
    assert_select "td", text: @patient.email
    assert_select "td", text: "question@example.test"
    assert_select "td", text: "mobile@example.test"
    assert_select "a", text: "Reply", count: 0
    assert_select "tr.clickable-row[data-controller='row-link']", minimum: 3
  end

  test "last super admin cannot suspend or deactivate their own account" do
    post suspend_admin_user_path(@admin)
    assert_redirected_to admin_user_path(@admin)
    assert_equal "active", @admin.reload.status

    delete deactivate_admin_user_path(@admin)
    assert_redirected_to admin_user_path(@admin)
    assert_nil @admin.reload.deleted_at
  end
end
