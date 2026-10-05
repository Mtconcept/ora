class AddAdminUserManagement < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :role, :string, null: false, default: "customer"
    add_column :users, :status, :string, null: false, default: "active"
    add_column :users, :last_login_at, :datetime
    add_column :users, :last_active_at, :datetime
    add_column :users, :login_count, :integer, null: false, default: 0
    add_column :users, :deleted_at, :datetime

    add_index :users, :email
    add_index :users, :role
    add_index :users, :status
    add_index :users, :deleted_at

    create_table :admin_audit_events do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :target_user, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.json :previous_value
      t.json :new_value
      t.string :ip_address
      t.timestamps
    end

    execute <<~SQL.squish
      UPDATE users
      SET role = CASE WHEN admin = 1 THEN 'super_admin' ELSE 'customer' END
    SQL
  end

  def down
    drop_table :admin_audit_events
    remove_index :users, :deleted_at
    remove_index :users, :status
    remove_index :users, :role
    remove_index :users, :email
    remove_column :users, :deleted_at
    remove_column :users, :login_count
    remove_column :users, :last_active_at
    remove_column :users, :last_login_at
    remove_column :users, :status
    remove_column :users, :role
  end
end
