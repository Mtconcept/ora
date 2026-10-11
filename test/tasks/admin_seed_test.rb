require "test_helper"
require "rake"

class AdminSeedTest < ActiveSupport::TestCase
  test "seeds one active administrator from environment variables" do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:seed")
    task = Rake::Task["admin:seed"]
    ENV["ORA_ADMIN_EMAIL"] = "Admin@MyOra.Care"
    ENV["ORA_ADMIN_PASSWORD"] = "test-password-only"

    2.times do
      task.reenable
      task.invoke
    end

    admin = User.find_by!(email: "admin@myora.care")
    assert_equal 1, User.where(email: admin.email).count
    assert_equal "super_admin", admin.role
    assert admin.active_for_authentication?
    assert admin.authenticate("test-password-only")
  ensure
    ENV.delete("ORA_ADMIN_EMAIL")
    ENV.delete("ORA_ADMIN_PASSWORD")
    task&.reenable
  end

  test "does not promote an existing customer" do
    customer = User.create!(phone: "+2348099990999", email: "admin@myora.care")
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:seed")
    task = Rake::Task["admin:seed"]
    ENV["ORA_ADMIN_EMAIL"] = customer.email
    ENV["ORA_ADMIN_PASSWORD"] = "test-password-only"

    task.reenable
    assert_raises(RuntimeError) { task.invoke }
    assert_equal "customer", customer.reload.role
  ensure
    ENV.delete("ORA_ADMIN_EMAIL")
    ENV.delete("ORA_ADMIN_PASSWORD")
    task&.reenable
  end
end
