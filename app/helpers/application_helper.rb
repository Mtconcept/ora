module ApplicationHelper
  def money(value) = number_to_currency(value || 0, unit: "₦", precision: 0)
  def monthly(value, term = 12) = (value.to_i * 1.12r / term).ceil
  def label_for(value) = value.to_s.humanize
  def icon(name, size: 22)
    paths = {
      "arrow" => '<path d="M4 12h15m-6-6 6 6-6 6"/>',
      "diagonal" => '<path d="M6 18 18 6M6 6h12v12"/>',
      "check" => '<path d="m5 12 4 4 10-10"/>',
      "shield" => '<path d="m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Z"/><path d="m8 12 3 3 5-5"/>',
      "heart" => '<path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>',
      "eye" => '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
      "tooth" => '<path d="M7 3C2 3 3 10 5 14s2 7 4 7c2 0 1-7 3-7s1 7 3 7c2 0 2-3 4-7s3-11-2-11c-3 0-3 2-5 2S10 3 7 3Z"/>',
      "spark" => '<path d="m12 2 3 7 7 3-7 3-3 7-3-7-7-3 7-3 3-7Z"/>',
      "search" => '<circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/>',
      "pin" => '<path d="M19 10c0 6-7 12-7 12S5 16 5 10a7 7 0 1 1 14 0Z"/><circle cx="12" cy="10" r="2"/>',
      "calendar" => '<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M7 2v6m10-6v6M3 11h18"/>',
      "menu" => '<path d="M4 7h16M4 12h16M4 17h16"/>',
      "grid" => '<rect x="3" y="3" width="7" height="7" rx="1"/><rect x="14" y="3" width="7" height="7" rx="1"/><rect x="3" y="14" width="7" height="7" rx="1"/><rect x="14" y="14" width="7" height="7" rx="1"/>',
      "users" => '<circle cx="9" cy="7" r="4"/><path d="M2 21v-2a7 7 0 0 1 14 0v2M17 3a4 4 0 0 1 0 8m2 4a6 6 0 0 1 3 6"/>',
      "wallet" => '<rect x="3" y="5" width="18" height="15" rx="2"/><path d="M3 7V4l14-2v3m4 7h-6v5h6"/>',
      "mail" => '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 5 9 8 9-8"/>',
      "logout" => '<path d="M9 3H4v18h5m5-14 5 5-5 5m-6-5h11"/>',
      "lock" => '<rect x="5" y="10" width="14" height="11" rx="2"/><path d="M8 10V6a4 4 0 0 1 8 0v4m-4 5v2"/>',
      "phone" => '<rect x="6" y="2" width="12" height="20" rx="3"/><path d="M10 5h4m-3 14h2"/>'
    }
    content_tag(:svg, (paths[name] || paths["spark"]).html_safe, width: size, height: size, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", 'stroke-width': 1.4, 'stroke-linecap': "round", 'stroke-linejoin': "round", 'aria-hidden': true)
  end
  def category_icon(category) = { "Dental" => "tooth", "Vision" => "eye", "Cosmetic" => "spark" }[category]

  # Compact version of Ora's six-petal mark for small UI placements.
  def ora_mark(size: 26)
    content_tag(:svg, '<path fill="currentColor" fill-rule="evenodd" d="M24 2c5.1 0 8.2 3.6 8.5 7.5 3.5-1.7 8.1-.8 10.6 3.6 2.5 4.4 1.2 8.9-2 11 3.2 2.1 4.5 6.6 2 11-2.5 4.4-7.1 5.3-10.6 3.6C32.2 42.4 29.1 46 24 46s-8.2-3.6-8.5-7.5c-3.5 1.7-8.1.8-10.6-3.6-2.5-4.4-1.2-8.9 2-11-3.2-2.1-4.5-6.6-2-11 2.5-4.4 7.1-5.3 10.6-3.6C15.8 5.6 18.9 2 24 2Zm0 13.3c-1.7 0-2.8 1.5-4.2 1.5-1.4 0-2.6-.6-4.1.2-1.5.9-1.9 2.3-1.1 3.5-.9 1.4-2.3 1.8-2.3 3.5s1.4 2.1 2.3 3.5c-.8 1.2-.4 2.6 1.1 3.5 1.5.8 2.7.2 4.1.2 1.4 0 2.5 1.5 4.2 1.5s2.8-1.5 4.2-1.5c1.4 0 2.6.6 4.1-.2 1.5-.9 1.9-2.3 1.1-3.5.9-1.4 2.3-1.8 2.3-3.5s-1.4-2.1-2.3-3.5c.8-1.2.4-2.6-1.1-3.5-1.5-.8-2.7-.2-4.1-.2-1.4 0-2.5-1.5-4.2-1.5Z"/>'.html_safe,
      width: size, height: size, viewBox: "0 0 48 48", 'aria-hidden': true)
  end
  def status_badge(value) = content_tag(:span, label_for(value), class: "badge badge-#{value}")

  ADMIN_ICONS = {
    "dashboard" => "grid", "customers" => "people", "journeys" => "heart_pulse", "providers" => "doctor",
    "procedures" => "clipboard_pulse", "pricing" => "receipt_money", "inbox" => "mail_inbox", "users" => "person",
    "appointments" => "calendar_ltr", "attention" => "alert", "settings" => "settings", "logout" => "sign_out", "search" => "search",
    "plus" => "add", "chevron" => "chevron_right", "activity" => "history", "external" => "open",
    "more" => "more_horizontal", "check" => "checkmark"
  }.freeze
  FLUENT_ICONS = Concurrent::Map.new

  # Microsoft Fluent UI System Icons (app/assets/images/icons/fluent, MIT). Each glyph renders on its
  # native 16px or 20px grid so it stays crisp; the filled variant marks the active item.
  def admin_icon(name, size: 20, filled: false)
    glyph = ADMIN_ICONS.fetch(name, "grid")
    grid = size <= 16 && fluent_icon(glyph, 16, "regular") ? 16 : 20
    style = filled && fluent_icon(glyph, grid, "filled") ? "filled" : "regular"
    content_tag(:svg, fluent_icon(glyph, grid, style), width: size, height: size, viewBox: "0 0 #{grid} #{grid}", fill: "currentColor", "aria-hidden": true)
  end

  def admin_nav_link(label, path, icon_name, active)
    link_to path, class: ("active" if active), aria: { current: ("page" if active) } do
      admin_icon(icon_name, filled: active) + content_tag(:span, label)
    end
  end

  def fluent_icon(glyph, grid, style)
    FLUENT_ICONS.fetch_or_store("#{glyph}_#{grid}_#{style}") do |key|
      file = Rails.root.join("app/assets/images/icons/fluent/#{key}.svg")
      file.exist? && file.read[%r{<svg[^>]*>(.*)</svg>}m, 1].gsub(/\sfill="[^"]*"/, "").html_safe
    end
  end

  # Care journey phases (CareCase::PHASES) drive the stage rail on a care record.
  def phase_for(key) = CareCase::PHASES.find { |phase| phase[:key] == key } || CareCase::PHASES.first
  def phase_name(key) = phase_for(key)[:name]
  def wat(time, fallback = "Not yet requested") = time ? time.strftime("%d %b %Y, %H:%M WAT") : fallback
  def section_label(text) = content_tag(:h2, text, class: "section-label")

  # Both stepper rails render from the same shape: a step is a name, a state, and somewhere to go.
  def care_stepper_steps(care)
    CareCase::PHASES.each_with_index.map do |phase, index|
      { key: phase[:key], name: phase[:name], blurb: phase[:blurb], number: index + 1,
        state: care.phase_state(phase[:key]), href: admin_case_path(care, section: phase[:key]) }
    end
  end

  def provider_stepper_steps(provider)
    Provider::STAGES.each_with_index.map do |stage, index|
      state = provider.new_record? ? (index.zero? ? "current" : "upcoming") : provider.stage_state(stage[:key])
      { key: stage[:key], name: stage[:name], blurb: stage[:blurb], number: index + 1, state: state,
        href: (stage_admin_provider_path(provider, stage: stage[:key]) unless provider.new_record?) }
    end
  end

  def provider_stage_name(key) = Provider::STAGES.find { |stage| stage[:key] == key }[:name]

  def lookup_for(kind)
    case kind
    when "place" then Lookup.place(nil)
    when "facility" then Lookup.facility(nil)
    when "bank" then Lookup.bank_account(nil, nil)
    else Lookup.organisation(nil)
    end
  end
  def check_status(provider, kind) = provider.check(kind)&.status || "pending"

  def admin_sort_link(label, column)
    next_direction = @sort == column && @direction == "asc" ? "desc" : "asc"
    marker = @sort == column ? (@direction == "asc" ? " ↑" : " ↓") : ""
    link_to "#{label}#{marker}", url_for(request.query_parameters.merge(sort: column, direction: next_direction, page: nil))
  end
end
