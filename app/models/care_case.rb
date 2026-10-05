class CareCase < ApplicationRecord
  STATUSES = %w[new qualification consultation_booked medical_review treatment_plan financing_review funded treatment_booked completed cancelled].freeze
  FINANCE_STATUSES = %w[not_requested pending preapproved partial unavailable offered accepted funded].freeze
  # The ten workflow statuses group into five phases. Operations works one phase at a time, so the
  # care journey screen shows a phase rail and opens only the fields that phase is responsible for.
  PHASES = [
    { key: "intake", name: "Intake", blurb: "Consent, affordability and case owner.", statuses: %w[new qualification] },
    { key: "consultation", name: "Consultation", blurb: "Clinic date and confirmation.", statuses: %w[consultation_booked] },
    { key: "assessment", name: "Medical review", blurb: "Provider assessment and final price.", statuses: %w[medical_review] },
    { key: "financing", name: "Financing", blurb: "Partner decision and patient acceptance.", statuses: %w[treatment_plan financing_review funded] },
    { key: "treatment", name: "Treatment", blurb: "Treatment date, confirmation and completion.", statuses: %w[treatment_booked completed] }
  ].freeze
  PHASE_KEYS = PHASES.map { |phase| phase[:key] }.freeze
  belongs_to :user
  belongs_to :listing
  has_many :case_events, dependent: :destroy
  delegate :procedure, :provider, to: :listing
  before_validation :set_defaults, on: :create
  validates :reference, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :medical_status, inclusion: { in: %w[pending approved not_approved] }
  validates :financing_status, inclusion: { in: FINANCE_STATUSES }
  validates :final_price, :approved_amount, :monthly_payment, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :term_months, inclusion: { in: [ 6, 12, 18, 24 ] }
  validates :upfront_amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
  validate :workflow_integrity
  def cost = final_price || estimated_price
  def funding_gap = [ cost.to_i - approved_amount.to_i - upfront_amount.to_i, 0 ].max
  def ready_for_terms? = medical_status == "approved" && financing_status == "offered" && final_price.present? && lender_name.present? && financing_terms.present? && monthly_payment.present? && funding_gap.zero?
  def ready_to_book? = medical_status == "approved" && final_price.present? && (!financing_requested || (financing_status == "funded" && (upfront_amount.to_i.zero? || upfront_confirmed?)))
  def log!(actor, message) = case_events.create!(user: actor, message: message)

  def phase = PHASES.find { |candidate| candidate[:statuses].include?(status) } || PHASES.first
  def phase_index = PHASES.index(phase)
  def cancelled? = status == "cancelled"
  def finished? = status.in?(%w[completed cancelled])

  # Rail state for one phase: a completed journey shows every phase done, and otherwise everything
  # before the live phase reads as done.
  def phase_state(key)
    index = PHASE_KEYS.index(key)
    return "done" if status == "completed"
    return reached?(key) ? "done" : "upcoming" if cancelled?
    index < phase_index ? "done" : index == phase_index ? "current" : "upcoming"
  end

  # "cancelled" belongs to no phase, so a cancelled journey has no current step. Its rail shows
  # only the phases whose work was actually recorded before the journey stopped.
  def reached?(key)
    case key
    when "intake" then true
    when "consultation" then consultation_confirmed?
    when "assessment" then medical_status != "pending"
    when "financing" then financing_status == "funded"
    else treatment_confirmed?
    end
  end

  # The single thing operations should do next, and the phase that holds the fields for it.
  # `waiting` marks the steps that belong to the patient, the clinic or the lender rather than us.
  def next_step
    return { section: "treatment", message: "This journey was cancelled. Nothing further is required.", waiting: false } if cancelled?
    return { section: "treatment", message: "Treatment is complete. The patient can now leave a review.", waiting: true } if status == "completed"
    return { section: "intake", message: "Check the intake details, then move the stage on and assign an owner.", waiting: false } if status.in?(%w[new qualification])
    return { section: "consultation", message: "Waiting for the patient to request a consultation date.", waiting: true } if consultation_at.blank?
    return { section: "consultation", message: "Record the clinic's confirmation of #{consultation_at.strftime('%d %b, %H:%M WAT')}.", waiting: false } unless consultation_confirmed?
    return { section: "assessment", message: "Record the provider's medical assessment after the consultation.", waiting: false } if medical_status == "pending"
    return { section: "assessment", message: "The provider did not approve treatment. Agree next steps with the patient.", waiting: false } if medical_status == "not_approved"
    return { section: "assessment", message: "Record the final treatment price supplied by the provider.", waiting: false } if final_price.blank?
    financing_step || treatment_step
  end

  private

  def financing_step
    return nil unless financing_requested
    return { section: "financing", message: "Record the financing partner's decision.", waiting: false } if financing_status.in?(%w[not_requested pending preapproved partial])
    return { section: "financing", message: "Financing is unavailable. Agree a self-pay or revised plan with the patient.", waiting: false } if financing_status == "unavailable"
    return { section: "financing", message: "Waiting for the patient to accept the financing terms in My Care.", waiting: true } if financing_status == "offered"
    return { section: "financing", message: "Record funding once the partner confirms disbursement.", waiting: true } if financing_status == "accepted"
    return { section: "financing", message: "#{money_text(funding_gap)} of the treatment price is still uncovered.", waiting: false } if funding_gap.positive?
    return { section: "financing", message: "Confirm receipt of the patient's #{money_text(upfront_amount)} upfront contribution.", waiting: false } if upfront_amount.to_i.positive? && !upfront_confirmed?
    nil
  end

  def treatment_step
    return { section: "treatment", message: "Waiting for the patient to request a treatment date.", waiting: true } if treatment_at.blank?
    return { section: "treatment", message: "Record the clinic's confirmation of #{treatment_at.strftime('%d %b, %H:%M WAT')}.", waiting: false } unless treatment_confirmed?
    return { section: "treatment", message: "Treatment is booked for #{treatment_at.strftime('%d %b, %H:%M WAT')}.", waiting: true } if treatment_at > Time.current
    { section: "treatment", message: "Treatment has taken place. Mark the journey complete.", waiting: false }
  end

  def money_text(amount) = ActiveSupport::NumberHelper.number_to_currency(amount.to_i, unit: "₦", precision: 0)
  def set_defaults
    self.reference ||= "ORA-#{SecureRandom.hex(3).upcase}"
    self.estimated_price ||= listing&.price
  end
  def workflow_integrity
    errors.add(:base, "A consultation date is required before clinic confirmation.") if consultation_confirmed? && consultation_at.blank?
    errors.add(:base, "A treatment date is required before clinic confirmation.") if treatment_confirmed? && treatment_at.blank?
    errors.add(:base, "Record a positive upfront contribution before confirming its receipt.") if upfront_confirmed? && upfront_amount.to_i <= 0
    errors.add(:base, "The clinic must confirm the treatment booking before marking it complete.") if status == "completed" && !treatment_confirmed?
    if %w[offered accepted funded].include?(financing_status) && (medical_status != "approved" || final_price.blank? || lender_name.blank? || financing_terms.blank? || monthly_payment.blank? || approved_amount.blank?)
      errors.add(:base, "Medical approval, final price, lender, amount, monthly payment and terms are required before a financing offer.")
    end
    if %w[accepted funded].include?(financing_status) && terms_accepted_at.blank?
      errors.add(:base, "The patient must accept the financing terms before funding can be recorded.")
    end
    if %w[accepted funded].include?(financing_status) && funding_gap.positive?
      errors.add(:base, "The updated treatment price must be covered by financing before proceeding.")
    end
    if %w[treatment_booked completed].include?(status) && (!ready_to_book? || treatment_at.blank?)
      errors.add(:base, "Medical approval, a treatment date and any required funding must be in place.")
    end
    if status == "completed" && treatment_at && treatment_at > Time.current
      errors.add(:base, "Treatment cannot be completed before its scheduled date.")
    end
  end
end
