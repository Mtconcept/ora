class Provider < ApplicationRecord
  # Onboarding runs as a stepper, the same shape as a care journey: one stage open at a time, and
  # the workspace names the next thing to do rather than presenting one long form.
  STAGES = [
    { key: "organisation", name: "Organisation", blurb: "Registered entity and public profile." },
    { key: "locations", name: "Locations", blurb: "Where the provider treats patients." },
    { key: "services", name: "Services", blurb: "Procedures offered, priced against Ora's catalogue." },
    { key: "verification", name: "Verification", blurb: "Corporate, facility, contact and bank checks." },
    { key: "commercial", name: "Commercial", blurb: "Settlement account, fee and signed agreement." },
    { key: "review", name: "Review", blurb: "Everything Ora holds, then publish." }
  ].freeze
  STAGE_KEYS = STAGES.map { |stage| stage[:key] }.freeze
  CHECKS = [
    { kind: "corporate", name: "Corporate", blurb: "Business registration confirmed against the register." },
    { kind: "facility", name: "Healthcare facility", blurb: "Facility registration or licence confirmed." },
    { kind: "contact", name: "Contact", blurb: "Official phone and email reach the provider." },
    { kind: "bank", name: "Bank", blurb: "Settlement account belongs to the registered entity." }
  ].freeze
  REQUIRED_CHECKS = %w[corporate facility contact].freeze
  TYPES = [ "Dental clinic", "Eye clinic", "Cosmetic surgery clinic", "Multi-specialty hospital", "Day surgery centre" ].freeze
  CONSULTATION_MODES = { "in_person" => "In person", "virtual" => "Virtual" }.freeze
  BOOKING_PROCESSES = {
    "ora_coordinates" => "Ora requests an appointment from the provider",
    "provider_slots" => "Provider supplies available slots",
    "instant" => "Instant booking"
  }.freeze

  has_many :listings, dependent: :restrict_with_error
  has_many :procedures, through: :listings
  has_many :provider_locations, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :provider
  has_many :provider_verifications, dependent: :destroy, inverse_of: :provider
  scope :published, -> { where(published: true) }
  validates :name, :slug, presence: true
  validates :slug, uniqueness: true
  validates :registration_number, uniqueness: true, allow_blank: true
  validates :ora_fee_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :consultation_fee, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :booking_process, inclusion: { in: BOOKING_PROCESSES.keys }, allow_blank: true

  def to_param = slug
  def modes = consultation_modes.to_s.split(",").reject(&:blank?)
  def check(kind) = provider_verifications.find { |row| row.kind == kind }
  def verified_check?(kind) = check(kind)&.status == "verified"
  def draft? = !published?

  # The public site shows one line of location, so it tracks the first location on the record.
  def refresh_display_location!
    first = provider_locations.reload.first
    update_column(:location, first ? first.short_address.presence || first.name : nil)
  end

  # The public "verification recorded" tag is derived from the checklist, never set by hand.
  def refresh_verification!
    provider_verifications.reload
    update_column(:verified, REQUIRED_CHECKS.all? { |kind| verified_check?(kind) })
  end

  def stage_complete?(key)
    case key
    when "organisation" then [ legal_name, registration_number, name, provider_type, phone, email ].all?(&:present?)
    when "locations" then provider_locations.any?
    when "services" then listings.any?
    when "verification" then REQUIRED_CHECKS.all? { |kind| verified_check?(kind) }
    when "commercial" then [ bank_name, bank_account_number, ora_fee_percent, agreement_executed_at ].all?(&:present?)
    else published?
    end
  end

  def ready_to_publish? = STAGE_KEYS.excluding("review").all? { |key| stage_complete?(key) }
  def stage_index = STAGE_KEYS.index(STAGE_KEYS.find { |key| !stage_complete?(key) } || "review")

  # The rail reads left to right: finished stages are done, the first unfinished one is current.
  def stage_state(key)
    index = STAGE_KEYS.index(key)
    return "done" if stage_complete?(key)
    index == stage_index ? "current" : "upcoming"
  end

  # The single thing to do next, and the stage that holds the fields for it. `waiting` marks the
  # steps that belong to the provider rather than to Ora.
  def next_step
    return { section: "review", message: "This provider is published and visible to patients.", waiting: false } if published?
    return { section: "organisation", message: "Record the organisation's registration and public contact details.", waiting: false } unless stage_complete?("organisation")
    return { section: "locations", message: "Add at least one location where this provider treats patients.", waiting: false } unless stage_complete?("locations")
    return { section: "services", message: "Choose the procedures this provider offers and price them.", waiting: false } unless stage_complete?("services")
    verification_step || commercial_step || { section: "review", message: "Everything is recorded. Review the provider and publish.", waiting: false }
  end

  private

  def verification_step
    pending = REQUIRED_CHECKS.reject { |kind| verified_check?(kind) }
    return nil if pending.empty?
    names = pending.map { |kind| CHECKS.find { |row| row[:kind] == kind }[:name].downcase }
    { section: "verification", message: "Still to verify: #{names.to_sentence}.", waiting: false }
  end

  def commercial_step
    return { section: "commercial", message: "Record the settlement account and bank, then verify it.", waiting: false } if bank_account_number.blank? || bank_name.blank?
    return { section: "commercial", message: "Record Ora's commercial fee for this provider.", waiting: false } if ora_fee_percent.blank?
    return { section: "commercial", message: "Waiting for the signed agreement before this provider can be published.", waiting: true } if agreement_executed_at.blank?
    nil
  end
end
