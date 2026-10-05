class AddCareConfirmations < ActiveRecord::Migration[8.1]
  def change
    add_column :care_cases, :consultation_confirmed, :boolean, null: false, default: false
    add_column :care_cases, :treatment_confirmed, :boolean, null: false, default: false
    add_column :care_cases, :upfront_amount, :integer, null: false, default: 0
    add_column :care_cases, :upfront_confirmed, :boolean, null: false, default: false
  end
end
