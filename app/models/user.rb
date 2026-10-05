class User < ApplicationRecord
  ROLES = %w[customer admin super_admin].freeze
  STATUSES = %w[active suspended pending deactivated].freeze

  has_secure_password validations: false
  has_many :care_cases, dependent: :restrict_with_error
  has_many :saved_procedures, dependent: :destroy
  has_many :procedures, through: :saved_procedures
  has_many :admin_audit_events, foreign_key: :actor_id, dependent: :restrict_with_error, inverse_of: :actor
  normalizes :phone, with: ->(v) { v.to_s.gsub(/[^\d+]/, "").sub(/\A0/, "+234") }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }
  validates :phone, presence: true, uniqueness: true, format: { with: /\A\+?\d{10,15}\z/ }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, if: :staff?
  validates :role, inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }

  scope :kept, -> { where(deleted_at: nil) }
  scope :staff, -> { kept.where(role: %w[admin super_admin]) }
  scope :customers, -> { kept.where(role: "customer") }

  def name = [ first_name, last_name ].compact.join(" ").presence || "Your Ora account"
  def staff? = role.in?(%w[admin super_admin])
  def super_admin? = role == "super_admin"
  def active_for_authentication? = status == "active" && deleted_at.nil?
  def soft_deleted? = deleted_at.present?
end
