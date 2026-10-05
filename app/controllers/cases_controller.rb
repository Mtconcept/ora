class CasesController < ApplicationController
  before_action :require_user
  before_action :load_case, except: [ :index, :create ]
  def index
    @cases = current_user.care_cases.includes(listing: [ :provider, :procedure ]).order(created_at: :desc)
    @saved = current_user.procedures.published
  end
  def show; end
  def consultation; end
  def plan; end
  def create
    redirect_to procedures_path
  end
  def book_consultation
    return reject("This journey is no longer active.") if %w[cancelled completed].include?(@case.status)
    return reject("Your consultation has already been assessed. Contact Ora to arrange another.") if @case.medical_status != "pending"
    date = parse_slot(params[:date], params[:time])
    return reject("Choose a weekday in the next 60 days and an available time.") unless date
    return reject("Choose an in-person or virtual consultation.") unless %w[in_person virtual].include?(params[:mode])
    @case.with_lock do
      @case.update!(consultation_at: date, consultation_confirmed: false, consultation_mode: params[:mode], status: "consultation_booked")
      @case.log!(current_user, "Consultation requested for #{date.strftime('%d %b %Y, %H:%M')} WAT. Awaiting clinic confirmation.")
    end
    redirect_to case_path(@case), notice: "Your consultation request is saved. Ora will confirm availability with the clinic."
  end
  def accept_terms
    @case.with_lock do
      return reject("This care journey is no longer active.") if %w[cancelled completed].include?(@case.status)
      return reject("Your treatment plan is not ready for acceptance.") unless @case.ready_for_terms?
      return reject("Please read and accept the financing terms.") unless params[:consent] == "1"
      @case.update!(financing_status: "accepted", terms_accepted_at: Time.current, status: "financing_review")
      @case.log!(current_user, "Patient accepted the recorded financing terms. Funding confirmation pending.")
    end
    redirect_to case_path(@case), notice: "Your acceptance is recorded. Ora will update you when funding is confirmed."
  end
  def book_treatment
    @case.with_lock do
      return reject("This journey is no longer active.") if %w[cancelled completed].include?(@case.status)
      return reject("Medical approval and any required funding must be confirmed first.") unless @case.ready_to_book?
      date = parse_slot(params[:date], params[:time])
      return reject("Please choose a weekday in the next 60 days and an available time.") unless date
      @case.update!(treatment_at: date, treatment_confirmed: false, status: "treatment_booked")
      @case.log!(current_user, "Patient requested a treatment date. Clinic confirmation pending.")
    end
    redirect_to case_path(@case), notice: "Your preferred treatment date has been sent to the Ora team."
  end
  def cancel
    @case.with_lock do
      return reject("Contact Ora to discuss cancellation after financing or treatment has advanced.") if %w[completed funded treatment_booked].include?(@case.status) || %w[accepted funded].include?(@case.financing_status)
      @case.update!(status: "cancelled")
      @case.log!(current_user, "Patient cancelled this care journey.")
    end
    redirect_to my_care_path, notice: "Your care journey has been cancelled."
  end
  def review
    return reject("You can leave a review after treatment is completed.") unless @case.status == "completed"
    if @case.update(params.permit(:rating, :review))
      redirect_to case_path(@case), notice: "Thank you. Your experience helps us improve care."
    else
      reject(@case.errors.full_messages.to_sentence)
    end
  end
  def request_revision
    return reject("This journey is no longer active.") if %w[cancelled completed].include?(@case.status)
    return reject("Contact Ora to discuss changes to confirmed funding.") if @case.financing_status == "funded"
    @case.with_lock do
      @case.update!(financing_requested: true, financing_status: "pending", terms_accepted_at: nil, status: "qualification")
      @case.log!(current_user, "Patient requested a revised financing review.")
    end
    redirect_to case_path(@case), notice: "The Ora team will review your updated financing options."
  end
  private
  def load_case
    @case = current_user.care_cases.includes(listing: [ :provider, :procedure ]).find(params[:id])
  end
  def reject(message)
    redirect_to case_path(@case), alert: message
  end
  def parse_slot(date, time)
    return unless %w[09:00 11:00 14:00 16:00].include?(time)
    value = Time.zone.strptime("#{date} #{time}", "%Y-%m-%d %H:%M") rescue nil
    value if value && value > Time.current && value < 61.days.from_now && !value.saturday? && !value.sunday?
  end
end
