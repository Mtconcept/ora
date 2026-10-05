class JourneyController < ApplicationController
  before_action :require_user, except: :start
  STEPS = %w[personal employment budget consent result].freeze
  def start
    listing = Listing.available.find(params[:listing_id])
    session[:journey] = { "listing_id" => listing.id, "mode" => params[:mode] == "self_pay" ? "self_pay" : "finance" }
    redirect_to journey_path("personal")
  end
  def show
    return redirect_to procedures_path, notice: "Choose a procedure to begin." unless load_journey
    @step = STEPS.include?(params[:step]) ? params[:step] : "personal"
    if @step == "result"
      @case = current_user.care_cases.find_by(id: @data["case_id"])
      redirect_to journey_path("personal") unless @case
    end
  end
  def update
    return redirect_to procedures_path unless load_journey
    @step = params[:step]
    permitted = params.permit(:date_of_birth, :area, :employment, :monthly_income, :monthly_budget, :consent).to_h
    @data.merge!(permitted)
    # The first step asks how the patient wants to pay, so a single "start" entry serves both paths.
    @data["mode"] = params[:mode] == "self_pay" ? "self_pay" : "finance" if @step == "personal" && params[:mode].present?
    session[:journey] = @data
    next_step = case @step
    when "personal"
      dob = Date.iso8601(@data["date_of_birth"]) rescue nil
      return invalid("Please enter your area and a date of birth. You must be 18 or older.") unless dob && dob <= 18.years.ago.to_date && dob > 110.years.ago.to_date && @data["area"].present?
      @data["mode"] == "self_pay" ? "consent" : "employment"
    when "employment"
      return invalid("Please select your employment and income range.") unless %w[Employed Self-employed Business-owner Freelancer Other].include?(@data["employment"]) && [ 150000, 350000, 750000, 1500000, 2500000 ].include?(@data["monthly_income"].to_i)
      "budget"
    when "budget"
      return invalid("Please enter a monthly budget between ₦10,000 and ₦2,000,000.") unless @data["monthly_budget"].to_i.between?(10000, 2000000)
      "consent"
    when "consent"
      return invalid("Please confirm your consent to continue.") unless params[:consent] == "1"
      return redirect_to journey_path("result") if @data["case_id"]
      dob = Date.iso8601(@data["date_of_birth"]) rescue nil
      return redirect_to journey_path("personal"), alert: "Please complete your personal details first." unless dob && dob <= 18.years.ago.to_date && @data["area"].present?
      finance = @data["mode"] != "self_pay"
      if finance && (@data["employment"].blank? || @data["monthly_income"].to_i <= 0 || !@data["monthly_budget"].to_i.between?(10000, 2000000))
        return redirect_to journey_path("employment"), alert: "Please complete your affordability details first."
      end
      care = current_user.care_cases.create!(listing: @listing, financing_requested: finance, financing_status: finance ? "pending" : "not_requested", status: "qualification", date_of_birth: dob, area: @data["area"], employment: @data["employment"], monthly_income: @data["monthly_income"], monthly_budget: @data["monthly_budget"], consented_at: Time.current)
      care.log!(current_user, finance ? "Affordability information submitted for manual review." : "Self-pay care journey started.")
      @data["case_id"] = care.id
      session[:journey] = @data
      "result"
    else
      "personal"
    end
    redirect_to journey_path(next_step)
  end
  private
  def load_journey
    @data = session[:journey] || {}
    @listing = Listing.available.includes(:procedure, :provider).find_by(id: @data["listing_id"])
  end
  def invalid(message)
    flash.now[:alert] = message
    render :show, status: :unprocessable_entity
  end
end
