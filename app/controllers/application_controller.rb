class ApplicationController < ActionController::Base
  helper_method :current_user, :signed_in?, :demo_mode?
  before_action :private_cache
  before_action :admin_host_only
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
    response.headers["Cache-Control"] = "no-store" if session[:user_id] || session[:admin_id] || session[:pending_admin_id] || controller_path.start_with?("admin/")
    response.headers["X-Robots-Tag"] = "noindex, nofollow, noarchive" if controller_path.start_with?("admin/") || request.host == "admin.myora.care"
  end

  def admin_host_only
    if ENV["ADMIN_HOST_ENFORCED"] == "1" && controller_path.start_with?("admin/") && request.host != "admin.myora.care"
      return redirect_to "https://admin.myora.care/admin/sign-in", status: :see_other, allow_other_host: true
    end

    return unless request.host == "admin.myora.care"
    return if controller_path.start_with?("admin/") || request.path.in?([ "/robots.txt", "/up" ])

    redirect_to admin_sign_in_path
  end
end
