class ProviderVerification < ApplicationRecord
  KINDS = Provider::CHECKS.map { |check| check[:kind] }.freeze
  STATUSES = %w[pending verified failed].freeze
  SOURCES = %w[lookup manual].freeze
  belongs_to :provider
  belongs_to :verified_by, class_name: "User", optional: true
  validates :kind, inclusion: { in: KINDS }, uniqueness: { scope: :provider_id }
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }
  # A manual pass is only as good as the note that explains it, so record why before recording that.
  validates :evidence, presence: true, if: -> { status == "verified" && source == "manual" }
  def verified? = status == "verified"
  def name = Provider::CHECKS.find { |check| check[:kind] == kind }[:name]
end
