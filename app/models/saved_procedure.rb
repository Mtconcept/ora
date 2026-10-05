class SavedProcedure < ApplicationRecord
  belongs_to :user
  belongs_to :procedure
  validates :procedure_id, uniqueness: { scope: :user_id }
end
