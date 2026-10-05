class ProceduresController < ApplicationController
  before_action :require_user, only: :save
  def index
    @procedures = Procedure.published
    @procedures = @procedures.where(category: params[:category]) if Procedure::CATEGORIES.include?(params[:category])
    @procedures = @procedures.where("name LIKE ?", "%#{Procedure.sanitize_sql_like(params[:q].to_s)}%") if params[:q].present?
    @procedures = @procedures.order(starting_price: :asc) if params[:sort] == "price"
  end
  def show
    @procedure = Procedure.published.find_by!(slug: params[:slug])
    @listings = @procedure.listings.available.includes(:provider).order(:price)
  end
  def save
    procedure = Procedure.published.find_by!(slug: params[:slug])
    saved = current_user.saved_procedures.find_by(procedure: procedure)
    saved ? saved.destroy! : current_user.saved_procedures.create!(procedure: procedure)
    redirect_back fallback_location: procedure_path(procedure), notice: saved ? "Removed from your saved care." : "Saved to My Care."
  end
end
