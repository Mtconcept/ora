class Admin::ProvidersController < Admin::BaseController
  before_action :set_provider, except: [ :index, :new, :create ]

  def index
    @providers = Provider.includes(:provider_locations, :provider_verifications, :listings).order(:name)
    @providers = @providers.where(published: params[:state] == "published") if params[:state].in?(%w[published draft])
    @published_count = Provider.where(published: true).count
    @draft_count = Provider.where(published: false).count
  end

  def new
    @provider = Provider.new
    @stage = "organisation"
    @lookup = Lookup.organisation(nil)
  end

  # Onboarding opens on the organisation, so the first save is what creates the record.
  def create
    @provider = Provider.new(organisation_params.merge(published: false))
    @provider.name = @provider.legal_name if @provider.name.blank?
    @provider.slug = unique_slug(@provider.name)
    if @provider.save
      audit!("provider.created", current: @provider.name)
      redirect_to stage_admin_provider_path(@provider, stage: "organisation"), notice: "Draft provider created. Work through each stage, then publish."
    else
      @stage = "organisation"
      @lookup = Lookup.organisation(@provider.registration_number)
      render :new, status: :unprocessable_entity
    end
  end

  def stage
    @stage = requested_stage
    load_stage
  end

  def update_stage
    @stage = requested_stage
    saved = case @stage
    when "organisation" then save_organisation
    when "services" then save_services
    when "commercial" then @provider.update(commercial_params)
    else false
    end
    if saved
      redirect_to stage_admin_provider_path(@provider, stage: @stage), notice: "#{stage_name(@stage)} saved."
    else
      load_stage
      render :stage, status: :unprocessable_entity
    end
  end

  # Runs the external lookup a stage would use and re-renders it with whatever came back. Today every
  # source reports itself unavailable, so the stage falls through to its manual fields.
  def lookup
    @stage = requested_stage
    @lookup_query = params[:query]
    @lookup = case params[:kind]
    when "place" then Lookup.place(@lookup_query)
    when "facility" then Lookup.facility(@lookup_query)
    when "bank" then Lookup.bank_account(@lookup_query, params[:bank])
    else Lookup.organisation(@lookup_query)
    end
    load_stage
    render :stage
  end

  def add_location
    @stage = "locations"
    @location = @provider.provider_locations.build(location_params)
    @location.position = @provider.provider_locations.maximum(:position).to_i + 1
    if @location.save
      @provider.refresh_display_location!
      redirect_to stage_admin_provider_path(@provider, stage: "locations"), notice: "#{@location.name} added."
    else
      load_stage
      render :stage, status: :unprocessable_entity
    end
  end

  def remove_location
    location = @provider.provider_locations.find(params[:location_id])
    if location.listings.exists?
      redirect_to stage_admin_provider_path(@provider, stage: "locations"), alert: "Move the procedures offered at #{location.name} to another location first."
    else
      location.destroy!
      @provider.refresh_display_location!
      redirect_to stage_admin_provider_path(@provider, stage: "locations"), notice: "#{location.name} removed."
    end
  end

  # Records the outcome of one check. A manual pass has to say what was seen; the model enforces it.
  def record_check
    @stage = "verification"
    # Built standalone: a rejected check must not sit in the provider's loaded association and read
    # back as though it had passed.
    @check = @provider.provider_verifications.find_by(kind: params[:kind]) || ProviderVerification.new(provider: @provider, kind: params[:kind])
    @check.assign_attributes(check_params)
    @check.verified_at = @check.status == "verified" ? Time.current : nil
    @check.verified_by = current_admin
    if @check.save
      @provider.refresh_verification!
      audit!("provider.check.#{@check.kind}", previous: @check.source, current: @check.status)
      redirect_to stage_admin_provider_path(@provider, stage: "verification"), notice: "#{@check.name} check recorded."
    else
      load_stage
      render :stage, status: :unprocessable_entity
    end
  end

  def publish
    @stage = "review"
    unless @provider.ready_to_publish?
      @provider.errors.add(:base, "Every stage has to be complete before publishing. #{@provider.next_step[:message]}")
      load_stage
      return render :stage, status: :unprocessable_entity
    end
    if @provider.update(published: true)
      audit!("provider.published", current: @provider.name)
      redirect_to stage_admin_provider_path(@provider, stage: "review"), notice: "#{@provider.name} is published and visible to patients."
    else
      load_stage
      render :stage, status: :unprocessable_entity
    end
  end

  private

  def set_provider = @provider = Provider.find_by!(slug: params[:slug])
  def requested_stage = params[:stage].presence_in(Provider::STAGE_KEYS) || @provider.next_step[:section]
  def stage_name(key) = Provider::STAGES.find { |stage| stage[:key] == key }[:name]

  def unique_slug(name)
    base = name.to_s.parameterize.presence || "provider"
    slug = base
    slug = "#{base}-#{SecureRandom.hex(2)}" while Provider.exists?(slug: slug)
    slug
  end

  def load_stage
    @locations = @provider.provider_locations.to_a
    @location ||= ProviderLocation.new(country: "Nigeria")
    @check ||= nil
    return unless @stage.in?(%w[services review])

    @catalogue = Procedure.order(:category, :name).to_a
    @offerings = @provider.listings.includes(:procedure, :provider_location).index_by(&:procedure_id)
  end

  def save_organisation
    @provider.assign_attributes(organisation_params)
    @provider.slug = unique_slug(@provider.name) if @provider.name_changed? && @provider.draft?
    @provider.save
  end

  # One table saves every procedure at once: ticked rows become offerings, unticked rows go, unless a
  # care journey already depends on them. Consultation handling is saved alongside.
  def save_services
    rows = params[:services]&.to_unsafe_h || {}
    blocked = []
    Provider.transaction do
      # The consultation fields travel with this form, but the table alone is a valid save.
      @provider.update(consultation_params) if params[:provider].present?
      rows.each do |procedure_id, values|
        listing = @provider.listings.find_by(procedure_id: procedure_id)
        if values["offered"] == "1"
          listing ||= Listing.new(provider: @provider, procedure_id: procedure_id)
          listing.assign_attributes(price: values["price"], consultation_fee: values["consultation_fee"].presence,
                                    provider_location_id: values["provider_location_id"].presence, status: values["status"].presence || "active")
          @provider.errors.add(:base, "#{listing.procedure.name}: #{listing.errors.full_messages.to_sentence}") unless listing.save
        elsif listing&.care_cases&.exists?
          blocked << listing.procedure.name
        else
          listing&.destroy
        end
      end
      @provider.errors.add(:base, "#{blocked.to_sentence} cannot be removed while care journeys reference them.") if blocked.any?
      raise ActiveRecord::Rollback if @provider.errors.any?
    end
    @provider.errors.empty?
  end

  def organisation_params
    params.require(:provider).permit(:legal_name, :registration_number, :registration_status, :registration_type, :registered_on,
                                     :name, :provider_type, :phone, :email, :website, :whatsapp, :logo_url, :summary, :description,
                                     :qualifications, :years_practicing, :specialty)
  end

  def commercial_params
    params.require(:provider).permit(:bank_name, :bank_account_number, :bank_account_name, :ora_fee_percent, :settlement_terms,
                                     :agreement_executed_at, :agreement_effective_on, :special_terms)
  end

  def consultation_params
    permitted = params.require(:provider).permit(:consultation_fee, :booking_process, modes: [])

    { consultation_fee: permitted[:consultation_fee].presence, booking_process: permitted[:booking_process],
      consultation_modes: Array(permitted[:modes]).compact_blank.join(",") }
  end

  def location_params = params.require(:provider_location).permit(:name, :address_line, :city, :state, :country, :latitude, :longitude, :phone)
  def check_params = params.require(:check).permit(:status, :reference, :source, :evidence)
end
