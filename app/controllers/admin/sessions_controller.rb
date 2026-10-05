class Admin::SessionsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to admin_sign_in_path, alert: "Too many attempts. Try again in 10 minutes." }
  def new; end
  def create
    user = User.staff.find_by(email: params[:email].to_s.strip.downcase)
    if user&.active_for_authentication? && user.authenticate(params[:password].to_s)
      user.update_columns(last_login_at: Time.current, last_active_at: Time.current, login_count: user.login_count + 1)
      reset_session
      session[:admin_id] = user.id
      redirect_to admin_root_path
    else
      redirect_to admin_sign_in_path, alert: "The email or password is incorrect."
    end
  end
  def destroy
    reset_session
    redirect_to admin_sign_in_path
  end
end
