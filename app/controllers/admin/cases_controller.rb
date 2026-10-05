class Admin::CasesController < Admin::BaseController
  def index
    @cases = CareCase.includes(:user, listing: [ :provider, :procedure ]).order(updated_at: :desc)
    @cases = @cases.where(status: params[:status]) if CareCase::STATUSES.include?(params[:status])
    if params[:q].present?
      query = "%#{CareCase.sanitize_sql_like(params[:q])}%"
      @cases = @cases.joins(:user).where("care_cases.reference LIKE ? OR users.first_name LIKE ? OR users.last_name LIKE ?", query, query, query)
    end
  end
  def show
    @case = CareCase.find(params[:id])
    load_journey
  end
  def update
    @case = CareCase.find(params[:id])
    attributes = params.require(:care_case).permit(:status, :medical_status, :final_price, :approved_amount, :financing_status, :term_months, :lender_name, :monthly_payment, :financing_terms, :preparation, :internal_notes, :assigned_to, :consultation_confirmed, :treatment_confirmed, :upfront_amount, :upfront_confirmed)
    @case.with_lock do
      if (attributes[:final_price].present? && attributes[:final_price].to_i != @case.final_price) || %w[approved_amount upfront_amount term_months monthly_payment lender_name financing_terms].any? { |k| attributes.key?(k) && attributes[k].to_s != @case.public_send(k).to_s }
        if @case.financing_status == "funded"
          @case.errors.add(:base, "Funded terms cannot be edited. Contact the lender to handle a formal amendment.")
          load_journey
          return render :show, status: :unprocessable_entity
        end
        @case.terms_accepted_at = nil
        attributes[:financing_status] = "pending" if @case.financing_status == "accepted"
      end
      if @case.update(attributes)
        changes = @case.previous_changes.except("updated_at", "internal_notes", "financing_terms", "preparation").map { |key, _| key.humanize }.join(", ")
        @case.log!(current_admin, "Operations updated #{changes.presence || 'case notes'}.")
        redirect_to admin_case_path(@case, section: params[:section].presence), notice: "Care record updated. The patient’s My Care view is now current."
      else
        load_journey
        render :show, status: :unprocessable_entity
      end
    end
  end

  private

  # The rail opens on the phase that owns the work; an explicit `section` lets the team look ahead
  # or back without changing the journey itself.
  def load_journey
    requested = params[:section].presence_in(CareCase::PHASE_KEYS)
    @section = requested || @case.next_step[:section]
    @inquiries = SupportRequest.where(status: "open").where(user_id: @case.user_id).order(created_at: :desc)
  end
end
