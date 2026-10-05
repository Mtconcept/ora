class WaitlistEntry < ApplicationRecord
  normalizes :email, with: ->(v) { v.strip.downcase }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end
