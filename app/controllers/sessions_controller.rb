class SessionsController < ApplicationController
  rate_limit to: 10, within: 10.minutes, only: [ :create, :confirm ], with: -> { redirect_to sign_in_path, alert: "Too many attempts. Please try again in 10 minutes." }
  def new; end
  def create
    unless demo_mode?
      return redirect_to sign_in_path, alert: "Phone verification is not available yet. Please contact Ora support."
    end
    phone = params[:phone].to_s.gsub(/[^\d+]/, "").sub(/\A0/, "+234")
    user = User.find_or_initialize_by(phone: phone)
    if user.staff? || (user.persisted? && !user.active_for_authentication?)
      return redirect_to sign_in_path, alert: "Please use your personal phone number."
    end
    user.assign_attributes(params.permit(:first_name, :last_name, :email)) if user.new_record?
    unless user.valid? && user.first_name.present?
      return redirect_to sign_in_path, alert: "Please enter your name, a valid phone number and email."
    end
    if user.otp_sent_at && user.otp_sent_at > 30.seconds.ago
      return redirect_to sign_in_path, alert: "Please wait 30 seconds before requesting another code."
    end
    code = SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
    user.update!(otp_digest: BCrypt::Password.create(code), otp_expires_at: 5.minutes.from_now, otp_attempts: 0, otp_sent_at: Time.current)
    session[:pending_user_id] = user.id
    session[:demo_code] = code if demo_mode?
    redirect_to verify_path
  end
  def verify
    @user = User.find_by(id: session[:pending_user_id])
    redirect_to sign_in_path unless @user
  end
  def confirm
    user = User.find_by(id: session[:pending_user_id])
    valid = false
    user&.with_lock do
      if user.otp_digest && user.otp_expires_at&.future? && user.otp_attempts < 5
        user.increment!(:otp_attempts)
        valid = BCrypt::Password.new(user.otp_digest) == params[:code].to_s
        user.update!(otp_digest: nil, otp_expires_at: nil) if valid
      end
    end
    unless valid
      return redirect_to verify_path, alert: "That code is incorrect or expired. Codes expire after 5 minutes and 5 attempts."
    end
    destination = session[:return_to]
    journey = session[:journey]
    reset_session
    session[:user_id] = user.id
    user.update_columns(last_login_at: Time.current, last_active_at: Time.current, login_count: user.login_count + 1)
    session[:journey] = journey if journey
    redirect_to destination.presence || my_care_path, notice: "Welcome, #{user.first_name}."
  end
  def destroy
    reset_session
    redirect_to root_path, notice: "You have signed out."
  end
end
