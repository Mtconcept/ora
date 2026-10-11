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

  def totp_secret
    return if totp_secret_ciphertext.blank?

    totp_encryptor.decrypt_and_verify(totp_secret_ciphertext)
  end

  def totp_secret=(secret)
    self.totp_secret_ciphertext = totp_encryptor.encrypt_and_sign(secret)
  end

  def totp
    ROTP::TOTP.new(totp_secret, issuer: "Ora")
  end

  def verify_admin_code!(code)
    with_lock do
      step = totp.verify(code.to_s.strip, after: totp_last_used_at, drift_behind: 30)
      if step
        update!(totp_last_used_at: step)
        true
      else
        digest = Digest::SHA256.hexdigest(code.to_s.strip.upcase)
        return false unless totp_recovery_codes.include?(digest)

        update!(totp_recovery_codes: totp_recovery_codes - [ digest ])
        true
      end
    end
  end

  private

  def totp_encryptor
    key = Rails.application.key_generator.generate_key("ora-admin-totp", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
end
