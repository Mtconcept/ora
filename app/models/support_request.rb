class SupportRequest < ApplicationRecord
  belongs_to :user, optional: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { maximum: 3000 }
  validates :status, inclusion: { in: %w[open resolved] }
end
