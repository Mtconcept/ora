class ApplicationController < ActionController::Base
  helper_method :current_user, :signed_in?, :demo_mode?
  before_action :private_cache
  private
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  def signed_in? = current_user.present?
  def demo_mode? = !Rails.env.production?
  def require_user
    return if signed_in?
    session[:return_to] = request.fullpath if %w[GET HEAD].include?(request.request_method)
    redirect_to sign_in_path, notice: "A little introduction, then we’ll continue."
  end
  def private_cache
    response.headers["Cache-Control"] = "no-store" if session[:user_id] || session[:admin_id]
  end
end
