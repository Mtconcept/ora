class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :require_admin
  helper_method :current_admin

  private

  def current_admin
    @current_admin ||= User.staff.find_by(id: session[:admin_id], status: "active")
  end

  def require_admin
    redirect_to admin_sign_in_path, alert: "Please sign in to Ora operations." unless current_admin
  end

  def require_super_admin
    return if current_admin&.super_admin?

    redirect_to admin_users_path, alert: "Only a super admin can perform that action."
  end

  def audit!(action, target: nil, previous: nil, current: nil)
    AdminAuditEvent.create!(
      actor: current_admin,
      target_user: target,
      action: action,
      previous_value: previous,
      new_value: current,
      ip_address: request.remote_ip
    )
  end
end
