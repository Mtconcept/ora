class Admin::SessionsController < ApplicationController
  rate_limit to: 5, within: 10.minutes, only: :create, with: -> { redirect_to admin_sign_in_path, alert: "Too many attempts. Try again in 10 minutes." }
  rate_limit to: 5, within: 10.minutes, only: :confirm_two_factor, with: -> { redirect_to admin_two_factor_path, alert: "Too many attempts. Try again in 10 minutes." }

  def entry
    redirect_to session[:admin_id] ? admin_root_path : admin_sign_in_path
  end

  def new; end

  def create
    user = User.staff.find_by(email: params[:email].to_s.strip.downcase)
    if user&.active_for_authentication? && user.authenticate(params[:password].to_s)
      reset_session
      session[:pending_admin_id] = user.id
      redirect_to admin_two_factor_path
    else
      redirect_to admin_sign_in_path, alert: "The email or password is incorrect."
    end
  end

  def two_factor
    user = pending_admin
    return redirect_to admin_sign_in_path unless user

    unless user.totp_confirmed_at?
      user.update!(totp_secret: ROTP::Base32.random) if user.totp_secret.blank?
      @secret = user.totp_secret
    end
    @email = user.email
  end

  def confirm_two_factor
    user = pending_admin
    return redirect_to admin_sign_in_path unless user

    if user.totp_confirmed_at?
      return redirect_to admin_two_factor_path, alert: "That code did not work." unless user.verify_admin_code!(params[:code])

      finish_sign_in(user)
      redirect_to admin_root_path
    else
      user.with_lock do
        step = user.totp.verify(params[:code].to_s.strip, after: user.totp_last_used_at, drift_behind: 30)
        return redirect_to admin_two_factor_path, alert: "That code did not work." unless step

        @recovery_codes = Array.new(8) { SecureRandom.base58(14) }
        user.update!(totp_confirmed_at: Time.current, totp_last_used_at: step,
                     totp_recovery_codes: @recovery_codes.map { |code| Digest::SHA256.hexdigest(code.upcase) })
      end
      finish_sign_in(user)
      render :recovery_codes
    end
  end

  def destroy
    reset_session
    redirect_to admin_sign_in_path
  end

  private

  def pending_admin
    User.staff.find_by(id: session[:pending_admin_id], status: "active")
  end

  def finish_sign_in(user)
    user.update_columns(last_login_at: Time.current, last_active_at: Time.current, login_count: user.login_count + 1)
    reset_session
    session[:admin_id] = user.id
  end
end
