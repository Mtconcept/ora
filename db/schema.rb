# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_21_000000) do
  create_table "admin_audit_events", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.json "new_value"
    t.json "previous_value"
    t.integer "target_user_id"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_admin_audit_events_on_actor_id"
    t.index ["target_user_id"], name: "index_admin_audit_events_on_target_user_id"
  end

  create_table "care_cases", force: :cascade do |t|
    t.integer "approved_amount"
    t.string "area"
    t.string "assigned_to"
    t.datetime "consented_at"
    t.datetime "consultation_at"
    t.boolean "consultation_confirmed", default: false, null: false
    t.string "consultation_mode"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "employment"
    t.integer "estimated_price"
    t.integer "final_price"
    t.boolean "financing_requested", default: false
    t.string "financing_status", default: "not_requested"
    t.text "financing_terms"
    t.text "internal_notes"
    t.string "lender_name"
    t.integer "listing_id", null: false
    t.string "medical_status", default: "pending"
    t.integer "monthly_budget"
    t.integer "monthly_income"
    t.integer "monthly_payment"
    t.text "preparation"
    t.integer "rating"
    t.string "reference", null: false
    t.text "review"
    t.string "status", default: "new", null: false
    t.integer "term_months", default: 12
    t.datetime "terms_accepted_at"
    t.datetime "treatment_at"
    t.boolean "treatment_confirmed", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "upfront_amount", default: 0, null: false
    t.boolean "upfront_confirmed", default: false, null: false
    t.integer "user_id", null: false
    t.index ["listing_id"], name: "index_care_cases_on_listing_id"
    t.index ["reference"], name: "index_care_cases_on_reference", unique: true
    t.index ["user_id"], name: "index_care_cases_on_user_id"
  end

  create_table "case_events", force: :cascade do |t|
    t.integer "care_case_id", null: false
    t.datetime "created_at", null: false
    t.string "message", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["care_case_id"], name: "index_case_events_on_care_case_id"
    t.index ["user_id"], name: "index_case_events_on_user_id"
  end

  create_table "listings", force: :cascade do |t|
    t.integer "consultation_fee"
    t.datetime "created_at", null: false
    t.integer "price", null: false
    t.integer "procedure_id", null: false
    t.integer "provider_id", null: false
    t.integer "provider_location_id"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["procedure_id", "provider_id"], name: "index_listings_on_procedure_id_and_provider_id", unique: true
    t.index ["procedure_id"], name: "index_listings_on_procedure_id"
    t.index ["provider_id"], name: "index_listings_on_provider_id"
    t.index ["provider_location_id"], name: "index_listings_on_provider_location_id"
  end

  create_table "procedures", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "image"
    t.string "name", null: false
    t.boolean "published", default: true
    t.string "recovery"
    t.string "slug", null: false
    t.integer "starting_price", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_procedures_on_slug", unique: true
  end

  create_table "provider_locations", force: :cascade do |t|
    t.string "address_line"
    t.string "city"
    t.string "country", default: "Nigeria", null: false
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "name", null: false
    t.string "phone"
    t.integer "position", default: 0, null: false
    t.integer "provider_id", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_provider_locations_on_provider_id"
  end

  create_table "provider_verifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "evidence"
    t.string "kind", null: false
    t.integer "provider_id", null: false
    t.string "reference"
    t.string "source", default: "manual", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.integer "verified_by_id"
    t.index ["provider_id", "kind"], name: "index_provider_verifications_on_provider_id_and_kind", unique: true
    t.index ["provider_id"], name: "index_provider_verifications_on_provider_id"
    t.index ["verified_by_id"], name: "index_provider_verifications_on_verified_by_id"
  end

  create_table "providers", force: :cascade do |t|
    t.date "agreement_effective_on"
    t.datetime "agreement_executed_at"
    t.string "bank_account_name"
    t.string "bank_account_number"
    t.string "bank_name"
    t.string "booking_process"
    t.integer "consultation_fee"
    t.string "consultation_modes"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.string "facility_registration"
    t.string "legal_name"
    t.string "location"
    t.string "logo_url"
    t.string "name", null: false
    t.decimal "ora_fee_percent", precision: 5, scale: 2
    t.string "phone"
    t.string "provider_type"
    t.boolean "published", default: true
    t.string "qualifications"
    t.date "registered_on"
    t.string "registration_number"
    t.string "registration_status"
    t.string "registration_type"
    t.string "settlement_terms"
    t.string "slug", null: false
    t.text "special_terms"
    t.string "specialty"
    t.text "summary"
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false
    t.string "website"
    t.string "whatsapp"
    t.integer "years_practicing"
    t.index ["registration_number"], name: "index_providers_on_registration_number", unique: true
    t.index ["slug"], name: "index_providers_on_slug", unique: true
  end

  create_table "saved_procedures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "procedure_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["procedure_id"], name: "index_saved_procedures_on_procedure_id"
    t.index ["user_id", "procedure_id"], name: "index_saved_procedures_on_user_id_and_procedure_id", unique: true
    t.index ["user_id"], name: "index_saved_procedures_on_user_id"
  end

  create_table "support_requests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.text "message", null: false
    t.string "status", default: "open"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_support_requests_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email"
    t.string "first_name"
    t.datetime "last_active_at"
    t.datetime "last_login_at"
    t.string "last_name"
    t.integer "login_count", default: 0, null: false
    t.integer "otp_attempts", default: 0
    t.string "otp_digest"
    t.datetime "otp_expires_at"
    t.datetime "otp_sent_at"
    t.string "password_digest"
    t.string "phone", null: false
    t.string "role", default: "customer", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email"
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["status"], name: "index_users_on_status"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_waitlist_entries_on_email", unique: true
  end

  add_foreign_key "admin_audit_events", "users", column: "actor_id"
  add_foreign_key "admin_audit_events", "users", column: "target_user_id"
  add_foreign_key "care_cases", "listings"
  add_foreign_key "care_cases", "users"
  add_foreign_key "case_events", "care_cases"
  add_foreign_key "case_events", "users"
  add_foreign_key "listings", "procedures"
  add_foreign_key "listings", "provider_locations"
  add_foreign_key "listings", "providers"
  add_foreign_key "provider_locations", "providers"
  add_foreign_key "provider_verifications", "providers"
  add_foreign_key "provider_verifications", "users", column: "verified_by_id"
  add_foreign_key "saved_procedures", "procedures"
  add_foreign_key "saved_procedures", "users"
  add_foreign_key "support_requests", "users"
end
