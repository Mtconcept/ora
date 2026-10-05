class Admin::CustomersController < Admin::BaseController
  def index
    contacts = registered_contacts + inquiry_contacts + waitlist_contacts
    contacts.select! { |contact| contact[:source] == params[:source] } if params[:source].present?
    if params[:q].present?
      query = params[:q].downcase.strip
      contacts.select! { |contact| [ contact[:name], contact[:email], contact[:phone] ].compact.any? { |value| value.downcase.include?(query) } }
    end
    @contacts = contacts.sort_by { |contact| contact[:last_seen] }.reverse
    @source_counts = @contacts.group_by { |contact| contact[:source] }.transform_values(&:count)
  end

  def show
    @customer = User.customers.find(params[:id])
    @requests = SupportRequest.where("user_id = ? OR lower(email) = ?", @customer.id, @customer.email.to_s.downcase).order(created_at: :desc)
    @cases = @customer.care_cases.includes(listing: %i[provider procedure]).order(created_at: :desc)
  end

  private

  def registered_contacts
    User.customers.includes(:care_cases).map do |user|
      {
        id: user.id, kind: "user", name: user.name, email: user.email, phone: user.phone,
        source: user.care_cases.any? ? "Care journey" : "Registered", status: user.status,
        activity: pluralize_count(user.care_cases.size, "care journey"), last_seen: user.last_active_at || user.created_at
      }
    end
  end

  def inquiry_contacts
    registered_emails = User.customers.where.not(email: nil).pluck(:email).map(&:downcase)
    SupportRequest.where.not(email: registered_emails).group_by { |request| request.email.downcase }.map do |email, requests|
      latest = requests.max_by(&:created_at)
      { kind: "inquiry", name: email.split("@").first.titleize, email: email, phone: nil, source: "Inquiry", status: latest.status, activity: pluralize_count(requests.size, "inquiry"), last_seen: latest.created_at }
    end
  end

  def waitlist_contacts
    known_emails = (User.customers.where.not(email: nil).pluck(:email) + SupportRequest.pluck(:email)).map(&:downcase)
    WaitlistEntry.where.not(email: known_emails).map do |entry|
      { kind: "waitlist", name: entry.email.split("@").first.titleize, email: entry.email, phone: nil, source: "Mobile waitlist", status: "active", activity: "Early access", last_seen: entry.created_at }
    end
  end

  def pluralize_count(count, noun)
    "#{count} #{noun.pluralize(count)}"
  end
end
