class ProviderLocation < ApplicationRecord
  belongs_to :provider
  has_many :listings, dependent: :nullify
  validates :name, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  def address = [ address_line, city, state, country ].compact_blank.join(", ")
  def short_address = [ city.presence || address_line, state ].compact_blank.join(", ")
  # The rail and review lists read "Lekki · Lekki Phase 1, Lagos" but just "Yaba, Lagos" when the
  # location is named after its own city.
  def label = short_address.blank? || short_address.start_with?(name) ? [ name, state ].compact_blank.uniq.join(", ") : "#{name} · #{short_address}"
end
