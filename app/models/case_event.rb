class CaseEvent < ApplicationRecord
  belongs_to :care_case
  belongs_to :user, optional: true
  validates :message, presence: true
end
