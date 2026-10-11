namespace :admin do
  desc "Create or update the production administrator from Railway variables"
  task seed: :environment do
    email = ENV.fetch("ORA_ADMIN_EMAIL").strip.downcase
    password = ENV.fetch("ORA_ADMIN_PASSWORD")
    raise "ORA_ADMIN_PASSWORD must not be blank" if password.blank?

    admin = User.find_or_initialize_by(email: email)
    raise "ORA_ADMIN_EMAIL already belongs to a customer" if admin.persisted? && !admin.staff?
    admin.assign_attributes(
      first_name: "Ora", last_name: "Admin", phone: admin.phone.presence || "+2348000000000",
      role: "super_admin", status: "active", admin: true, password: password
    )
    admin.save!
    puts "Administrator ready: #{admin.email}"
  end
end
