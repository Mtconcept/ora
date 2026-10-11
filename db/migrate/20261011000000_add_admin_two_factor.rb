class AddAdminTwoFactor < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :totp_secret_ciphertext, :text
    add_column :users, :totp_confirmed_at, :datetime
    add_column :users, :totp_last_used_at, :bigint
    add_column :users, :totp_recovery_codes, :json, default: [], null: false
  end
end
