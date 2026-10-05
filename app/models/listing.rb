class Listing < ApplicationRecord
  STATUSES = %w[active paused].freeze
  belongs_to :provider
  belongs_to :procedure
  # A blank location means the provider offers this procedure everywhere it operates.
  belongs_to :provider_location, optional: true
  has_many :care_cases, dependent: :restrict_with_error
  validates :price, numericality: { only_integer: true, greater_than: 0 }
  validates :consultation_fee, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, inclusion: { in: STATUSES }
  validates :procedure_id, uniqueness: { scope: :provider_id }
  scope :available, -> { joins(:provider, :procedure).where(status: "active", providers: { published: true }, procedures: { published: true }) }
  def where_offered = provider_location&.name || "All locations"
end
