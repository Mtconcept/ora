class ProvidersController < ApplicationController
  def index
    @providers = Provider.published
    @providers = @providers.where("name LIKE ? OR location LIKE ?", *Array.new(2, "%#{Provider.sanitize_sql_like(params[:q].to_s)}%")) if params[:q].present?
    listings = Listing.available.where(provider_id: @providers.select(:id))
    @listing_counts = listings.group(:provider_id).count
    @price_floors = listings.group(:provider_id).minimum(:price)
  end
  def show
    @provider = Provider.published.find_by!(slug: params[:slug])
    @listings = @provider.listings.available.includes(:procedure)
  end
end
