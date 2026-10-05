class PagesController < ApplicationController
  # The hero cycles through these treatments; its headline takes each phrase in turn and its
  # background crossfades to the option's scene (one of the hero videos).
  HERO_OPTIONS = [
    [ "braces-aligners", "Teeth", "Fix your teeth", "dental" ],
    [ "liposuction", "Body", "Reshape your body", "cosmetic" ],
    [ "lasik-eye-surgery", "Eyes", "See clearly again", "cosmetic" ],
    [ "dental-implants", "Teeth", "Restore your smile", "dental" ]
  ].freeze

  def home
    procedures = Procedure.published
    @procedures = procedures.order(:name).to_a
    @category_counts = procedures.group(:category).count
    @category_floors = procedures.group(:category).minimum(:starting_price)
    @provider_count = Provider.published.count
    @example = @procedures.find { |procedure| procedure.category == "Dental" } || @procedures.first
    by_slug = @procedures.index_by(&:slug)
    @hero_options = HERO_OPTIONS.filter_map { |slug, area, phrase, scene| { procedure: by_slug[slug], area:, phrase:, scene: } if by_slug[slug] }
  end
  def how; end
  def mobile; end
  def privacy; end
  def support
    @support = SupportRequest.new(email: current_user&.email)
  end
  def create_support
    @support = SupportRequest.new(params.require(:support_request).permit(:email, :message))
    @support.user = current_user
    if @support.save
      redirect_to support_path, notice: "Your message is with the Ora team. You can follow up here at any time."
    else
      render :support, status: :unprocessable_entity
    end
  end
  def affordability
    @budget = params.fetch(:budget, 75000).to_i.clamp(10000, 500000)
    @term = [ 6, 12, 18, 24 ].include?(params[:term].to_i) ? params[:term].to_i : 12
    @range = (@budget * @term / 1.12).floor
    @procedures = Procedure.published.where("starting_price <= ?", @range)
  end
  def waitlist
    entry = WaitlistEntry.new(email: params[:email])
    if entry.save || entry.errors.of_kind?(:email, :taken)
      redirect_to mobile_path, notice: "You’re on the list. We’ll let you know when Ora mobile is ready."
    else
      redirect_to mobile_path, alert: "Please enter a valid email address."
    end
  end
end
