class CreateOra < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :phone, null: false
      t.string :email
      t.boolean :admin, default: false, null: false
      t.string :password_digest
      t.string :otp_digest
      t.datetime :otp_expires_at
      t.integer :otp_attempts, default: 0
      t.datetime :otp_sent_at
      t.timestamps
    end
    add_index :users, :phone, unique: true
    create_table :procedures do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :category, null: false
      t.text :summary
      t.text :description
      t.string :recovery
      t.string :image
      t.integer :starting_price, null: false
      t.boolean :published, default: true
      t.timestamps
    end
    add_index :procedures, :slug, unique: true
    create_table :providers do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :location
      t.string :specialty
      t.text :description
      t.string :qualifications
      t.integer :years_practicing
      t.boolean :verified, default: false
      t.boolean :published, default: true
      t.timestamps
    end
    add_index :providers, :slug, unique: true
    create_table :listings do |t|
      t.references :procedure, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: true
      t.integer :price, null: false
      t.timestamps
    end
    add_index :listings, [ :procedure_id, :provider_id ], unique: true
    create_table :care_cases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.string :reference, null: false
      t.string :status, default: 'new', null: false
      t.boolean :financing_requested, default: false
      t.string :employment
      t.integer :monthly_income
      t.integer :monthly_budget
      t.date :date_of_birth
      t.string :area
      t.datetime :consented_at
      t.integer :estimated_price
      t.integer :final_price
      t.integer :approved_amount
      t.string :financing_status, default: 'not_requested'
      t.string :medical_status, default: 'pending'
      t.integer :term_months, default: 12
      t.string :lender_name
      t.text :financing_terms
      t.integer :monthly_payment
      t.datetime :terms_accepted_at
      t.datetime :consultation_at
      t.string :consultation_mode
      t.datetime :treatment_at
      t.text :preparation
      t.text :internal_notes
      t.string :assigned_to
      t.integer :rating
      t.text :review
      t.timestamps
    end
    add_index :care_cases, :reference, unique: true
    create_table :case_events do |t|
      t.references :care_case, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :message, null: false
      t.timestamps
    end
    create_table :saved_procedures do |t|
      t.references :user, null: false, foreign_key: true
      t.references :procedure, null: false, foreign_key: true
      t.timestamps
    end
    add_index :saved_procedures, [ :user_id, :procedure_id ], unique: true
    create_table :waitlist_entries do |t|
      t.string :email, null: false
      t.timestamps
    end
    add_index :waitlist_entries, :email, unique: true
    create_table :support_requests do |t|
      t.references :user, foreign_key: true
      t.string :email, null: false
      t.text :message, null: false
      t.string :status, default: 'open'
      t.timestamps
    end
  end
end
