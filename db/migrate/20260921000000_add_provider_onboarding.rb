class AddProviderOnboarding < ActiveRecord::Migration[8.1]
  def change
    change_table :providers, bulk: true do |t|
      # Organisation, as recorded against the business register.
      t.string :legal_name
      t.string :registration_number
      t.string :registration_status
      t.string :registration_type
      t.date :registered_on
      # Marketplace presence.
      t.string :provider_type
      t.string :phone
      t.string :email
      t.string :website
      t.string :whatsapp
      t.string :logo_url
      t.text :summary
      # Healthcare facility.
      t.string :facility_registration
      # Commercial and settlement.
      t.string :bank_name
      t.string :bank_account_number
      t.string :bank_account_name
      t.decimal :ora_fee_percent, precision: 5, scale: 2
      t.string :settlement_terms
      t.datetime :agreement_executed_at
      t.date :agreement_effective_on
      t.text :special_terms
      # Consultation handling.
      t.string :consultation_modes
      t.integer :consultation_fee
      t.string :booking_process
    end
    add_index :providers, :registration_number, unique: true

    create_table :provider_locations do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address_line
      t.string :city
      t.string :state
      t.string :country, null: false, default: "Nigeria"
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :phone
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    # One row per verification Ora requires, so a checklist always shows how each was satisfied.
    create_table :provider_verifications do |t|
      t.references :provider, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :reference
      t.string :source, null: false, default: "manual"
      t.text :evidence
      t.datetime :verified_at
      t.references :verified_by, foreign_key: { to_table: :users }
      t.timestamps
      t.index [ :provider_id, :kind ], unique: true
    end

    change_table :listings, bulk: true do |t|
      t.integer :consultation_fee
      t.references :provider_location, foreign_key: true
      t.string :status, null: false, default: "active"
    end
  end
end
