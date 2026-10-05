class Admin::SettingsController < Admin::BaseController
  def index
    @team_count = User.staff.count
    @audit_count = AdminAuditEvent.count
    @inquiry_count = SupportRequest.where(status: "open").count
    @waitlist_count = WaitlistEntry.count
  end

  def team
    @team = User.staff.order(role: :desc, first_name: :asc)
  end
end
