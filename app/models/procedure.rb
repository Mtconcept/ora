class Procedure < ApplicationRecord
  CATEGORIES = [ "Dental", "Vision", "Cosmetic" ].freeze
  has_many :listings, dependent: :restrict_with_error
  has_many :providers, through: :listings
  has_many :saved_procedures, dependent: :destroy
  scope :published, -> { where(published: true) }
  validates :name, :slug, :summary, presence: true
  validates :slug, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :starting_price, numericality: { only_integer: true, greater_than: 0 }
  def to_param = slug
end
