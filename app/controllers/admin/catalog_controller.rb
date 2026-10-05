class Admin::CatalogController < Admin::BaseController
  before_action :set_kind
  def index
    @records = @klass.includes(listings: :provider).order(:name)
    @records = @records.where("name LIKE ?", "%#{@klass.sanitize_sql_like(params[:q])}%") if params[:q].present?
  end
  def new = @record = @klass.new
  def edit
    @record = @klass.find(params[:id])
    @listings = @record.listings.includes(:provider, :provider_location).order(:price)
  end
  def create
    @record = @klass.new(record_params)
    @record.slug = @record.name.parameterize if @record.respond_to?(:slug) && @record.slug.blank?
    if @record.save
      redirect_to created_path, notice: "Catalog entry created."
    else
      render :new, status: :unprocessable_entity
    end
  end
  def update
    @record = @klass.find(params[:id])
    if @record.update(record_params)
      redirect_to after_save_path, notice: "Catalog entry updated."
    else
      @listings = @record.listings.includes(:provider, :provider_location).order(:price)
      render :edit, status: :unprocessable_entity
    end
  end
  private
  def set_kind
    @kind = params[:kind]
    @klass = { "procedures" => Procedure }[@kind]
    raise ActiveRecord::RecordNotFound unless @klass
  end
  def after_save_path = admin_catalog_path(@kind)
  # A new procedure opens on its own page, where the rest of its copy is written.
  def created_path = admin_edit_catalog_path(kind: "procedures", id: @record.id)
  def record_params
    params.require(:record).permit(:name, :slug, :category, :summary, :description, :recovery, :starting_price, :published)
  end
end
