class Admin::DashboardController < Admin::BaseController
  def index
    @cases = CareCase.includes(:user, listing: [ :provider, :procedure ]).order(updated_at: :desc)
    @active_count = @cases.where.not(status: %w[completed cancelled]).count
    @review_count = @cases.where(financing_status: "pending").count
    @customer_count = User.customers.count
    @inquiry_count = SupportRequest.where(status: "open").count
    # Journeys where the next move belongs to operations rather than the patient, clinic or lender.
    live = @cases.reject(&:finished?)
    @attention = live.reject { |care| care.next_step[:waiting] }
    @attention_count = @attention.size
    @upcoming = live.flat_map { |care|
      [
        ({ care: care, kind: "Consultation", at: care.consultation_at, confirmed: care.consultation_confirmed? } if care.consultation_at&.future?),
        ({ care: care, kind: "Treatment", at: care.treatment_at, confirmed: care.treatment_confirmed? } if care.treatment_at&.future?)
      ].compact
    }.sort_by { |entry| entry[:at] }.first(4)
    @events = CaseEvent.includes(:care_case, :user).order(created_at: :desc).limit(6)
  end
  def inbox
    @requests = SupportRequest.order(created_at: :desc)
    @waitlist = WaitlistEntry.order(created_at: :desc)
  end
  def resolve
    SupportRequest.find(params[:id]).update!(status: "resolved")
    redirect_to admin_inbox_path, notice: "Request marked as resolved."
  end
end
