require "test_helper"

class AdminTwoFactorTest < ActionDispatch::IntegrationTest
  setup { build_catalog }

  test "password alone cannot open admin; setup enables authenticator and recovery codes" do
    @admin.update!(totp_secret_ciphertext: nil, totp_confirmed_at: nil, totp_last_used_at: nil)
    post admin_sign_in_path, params: { email: @admin.email, password: "TestPassword2026!" }
    assert_redirected_to admin_two_factor_path
    get admin_root_path
    assert_redirected_to admin_sign_in_path
    get admin_two_factor_path
    assert_response :success
    assert_select ".admin-setup-key code", 1
    post admin_two_factor_path, params: { code: "000000" }
    assert_redirected_to admin_two_factor_path
    post admin_two_factor_path, params: { code: @admin.reload.totp.now }
    assert_response :success
    assert_select ".admin-recovery-codes li", 8
    assert @admin.reload.totp_confirmed_at?
    get admin_root_path
    assert_response :success
    @admin.update!(totp_confirmed_at: nil)
    get admin_root_path
    assert_redirected_to admin_sign_in_path
  end

  test "confirmed admin needs a fresh second factor and recovery codes are single use" do
    post admin_sign_in_path, params: { email: @admin.email, password: "TestPassword2026!" }
    code = @admin.totp.now
    post admin_two_factor_path, params: { code: code }
    assert_redirected_to admin_root_path
    delete admin_sign_out_path
    post admin_sign_in_path, params: { email: @admin.email, password: "TestPassword2026!" }
    post admin_two_factor_path, params: { code: code }
    assert_redirected_to admin_two_factor_path
    recovery = "TESTRECOVERYCODE"
    @admin.update!(totp_recovery_codes: [ Digest::SHA256.hexdigest(recovery) ])
    post admin_two_factor_path, params: { code: recovery.downcase }
    assert_redirected_to admin_root_path
    assert_empty @admin.reload.totp_recovery_codes
    delete admin_sign_out_path
    post admin_sign_in_path, params: { email: @admin.email, password: "TestPassword2026!" }
    post admin_two_factor_path, params: { code: recovery }
    assert_redirected_to admin_two_factor_path
  end

  test "admin host opens sign-in and stays out of search indexes" do
    previous = ENV["ADMIN_HOST_ENFORCED"]
    host! "admin.myora.care"
    get "/"
    assert_redirected_to admin_sign_in_path
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]
    get "/robots.txt"
    assert_includes response.body, "Disallow: /\n"
    get admin_sign_in_path
    assert_select "meta[name='robots'][content='noindex,nofollow,noarchive']", 1
    get procedures_path
    assert_redirected_to admin_sign_in_path
    host! "myora.care"
    get "/robots.txt"
    assert_includes response.body, "Disallow: /admin/\n"
    ENV["ADMIN_HOST_ENFORCED"] = "1"
    get admin_sign_in_path
    assert_redirected_to "https://admin.myora.care/admin/sign-in"
  ensure
    ENV["ADMIN_HOST_ENFORCED"] = previous
  end
end
