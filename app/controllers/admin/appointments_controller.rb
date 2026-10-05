class Admin::AppointmentsController < Admin::BaseController
  # Consultations and treatments are both dates on a care record. This reads them as one diary so
  # the team can see the week without opening every journey.
  def index
    @scope = params[:scope] == "past" ? "past" : "upcoming"
    entries = scheduled_cases.flat_map do |care|
      [
        ({ care: care, kind: "Consultation", at: care.consultation_at, confirmed: care.consultation_confirmed? } if care.consultation_at),
        ({ care: care, kind: "Treatment", at: care.treatment_at, confirmed: care.treatment_confirmed? } if care.treatment_at)
      ].compact
    end
    upcoming, past = entries.partition { |entry| entry[:at] >= Time.current }
    @upcoming_count = upcoming.size
    @past_count = past.size
    @unconfirmed_count = upcoming.count { |entry| !entry[:confirmed] }
    @appointments = @scope == "past" ? past.sort_by { |entry| -entry[:at].to_i } : upcoming.sort_by { |entry| entry[:at] }
  end

  private

  def scheduled_cases
    CareCase.includes(:user, listing: [ :provider, :procedure ])
            .where.not(status: "cancelled")
            .where("consultation_at IS NOT NULL OR treatment_at IS NOT NULL")
  end
end
