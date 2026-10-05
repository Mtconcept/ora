raise 'Demo seeds are disabled in production' if Rails.env.production?
admin = nil
if ENV["ORA_ADMIN_PASSWORD"].present?
  admin = User.find_or_initialize_by(phone: '+2348000000000')
  admin.assign_attributes(first_name: 'Ora', last_name: 'Operations', email: 'admin@ora.local', role: 'super_admin', status: 'active', admin: true, password: ENV.fetch('ORA_ADMIN_PASSWORD'))
  admin.save!
end
[
  [ 'Dental implants', 'Dental', 650000, 'A considered step towards a complete smile.', 'Explore options for replacing a missing tooth with a dental implant. Your clinician will explain the assessment, treatment stages, alternatives, and the final cost at your consultation.', 'Your clinician will confirm a personalised recovery timeline.' ],
  [ 'LASIK eye surgery', 'Vision', 850000, 'See the everyday in a whole new way.', 'Explore laser vision correction with an eye-care professional. A detailed eye assessment determines whether this procedure is appropriate for you and which options are available.', 'Your eye specialist will advise on recovery and follow-up.' ],
  [ 'Rhinoplasty', 'Cosmetic', 1800000, 'Explore a change that feels personal to you.', 'Meet a specialist to discuss your goals, available approaches, and alternatives. A consultation includes a medical assessment and a personalised treatment plan, with no obligation to proceed.', 'Recovery varies by treatment plan; discuss it with your surgeon.' ],
  [ 'Braces & aligners', 'Dental', 450000, 'A more confident smile, at your own pace.', 'Discuss orthodontic options with a qualified dental professional. Your assessment will cover alignment, suitable treatment options, expected duration, and ongoing appointments.', 'Your orthodontist will explain your treatment schedule.' ],
  [ 'Dental veneers', 'Dental', 750000, 'Thoughtful care for the smile you have in mind.', 'A dental consultation helps you understand veneer options, alternatives, preparation, and the care involved. Your dentist will advise whether this treatment suits your teeth.', 'Your dentist will provide individual aftercare guidance.' ],
  [ 'Breast reduction', 'Cosmetic', 2200000, 'Space to explore greater comfort.', 'Discuss your goals and concerns in a private consultation with a specialist. Suitability, risks, alternatives, and final pricing are determined after a medical assessment.', 'Your surgeon will advise on time away from work and activities.' ],
  [ 'Liposuction', 'Cosmetic', 1500000, 'A personal decision. A supported journey.', 'Speak with a specialist about your goals and whether a body-contouring procedure may be appropriate. Your clinician will discuss limitations, alternatives, risks, and recovery.', 'Your surgeon will provide a personalised recovery plan.' ],
  [ 'Comprehensive eye assessment', 'Vision', 85000, 'A clearer understanding of your eye health.', 'A consultation with an eye-care professional to discuss your vision and plan appropriate assessments. Ask your provider which examinations are included in your appointment.', 'Ask your clinician about any appointment preparation.' ]
].each do |name, category, price, summary, description, recovery|
  procedure = Procedure.find_or_initialize_by(slug: name.parameterize)
  procedure.update!(name: name, category: category, starting_price: price, summary: summary, description: description, recovery: recovery)
end
# Demonstration providers, onboarded the way the workspace asks for it: a registered organisation,
# locations, priced procedures, recorded checks and commercial terms.
[
  { name: 'Lumière Dental Studio', legal: 'Lumiere Dental Services Limited', rc: '1478221', type: 'Dental clinic', specialty: 'Dental', years: 12,
    description: 'A calm, appointment-led dental studio with an emphasis on considered, individual care.',
    phone: '+2348030001111', email: 'hello@lumiere.example', bank: 'GTBank', account: '0123456781',
    locations: [ [ 'Ikoyi', '14 Bourdillon Road', 'Ikoyi', 'Lagos' ] ], published: true },
  { name: 'Clarity Eye Centre', legal: 'Clarity Vision Care Limited', rc: '1582907', type: 'Eye clinic', specialty: 'Vision', years: 16,
    description: 'A dedicated eye-care practice designed around clear conversations and attentive consultations.',
    phone: '+2348030002222', email: 'hello@clarity.example', bank: 'Zenith Bank', account: '0123456782',
    locations: [ [ 'Victoria Island', '3 Adeola Odeku Street', 'Victoria Island', 'Lagos' ] ], published: true },
  { name: 'The Aster Clinic', legal: 'Aster Aesthetics Limited', rc: '1690455', type: 'Cosmetic surgery clinic', specialty: 'Cosmetic', years: 14,
    description: 'A private consultation setting for exploring aesthetic procedures with care and discretion.',
    phone: '+2348030003333', email: 'hello@aster.example', bank: 'Access Bank', account: '0123456783',
    locations: [ [ 'Lekki', '12 Admiralty Way', 'Lekki Phase 1', 'Lagos' ], [ 'Victoria Island', '9 Akin Adesola Street', 'Victoria Island', 'Lagos' ] ], published: true },
  { name: 'Meridian Care', legal: 'Meridian Health Partners Limited', rc: '1733018', type: 'Multi-specialty hospital', specialty: 'Dental', years: 10,
    description: 'A multidisciplinary practice bringing planned care and personal attention together.',
    phone: '+2348030004444', email: 'hello@meridian.example', bank: 'First Bank', account: '0123456784',
    locations: [ [ 'Maitama', '21 Gana Street', 'Maitama', 'Abuja' ] ], published: true },
  # Left mid-onboarding so the provider stepper has something to demonstrate.
  { name: 'Harbourline Surgical', legal: 'Harbourline Surgical Limited', rc: '1801664', type: 'Day surgery centre', specialty: 'Cosmetic', years: 6,
    description: 'A day-surgery centre being assessed for the Ora directory.',
    phone: '+2348030005555', email: 'hello@harbourline.example', bank: nil, account: nil,
    locations: [ [ 'Yaba', '5 Herbert Macaulay Way', 'Yaba', 'Lagos' ] ], published: false }
].each do |row|
  provider = Provider.find_or_initialize_by(slug: row[:name].parameterize)
  provider.assign_attributes(
    name: row[:name], legal_name: row[:legal], registration_number: row[:rc], registration_status: 'Active',
    registration_type: 'Private company', registered_on: Date.new(2018, 3, 14), provider_type: row[:type],
    specialty: row[:specialty], description: row[:description], qualifications: 'Demo qualification record — verification pending',
    years_practicing: row[:years], phone: row[:phone], email: row[:email], website: "https://#{row[:name].parameterize}.example",
    summary: row[:description].truncate(90), published: row[:published],
    bank_name: row[:bank], bank_account_number: row[:account], bank_account_name: row[:legal],
    ora_fee_percent: (7 if row[:published]), settlement_terms: ('Weekly settlement' if row[:published]),
    agreement_executed_at: (Time.zone.local(2026, 8, 1, 10) if row[:published]), agreement_effective_on: (Date.new(2026, 8, 1) if row[:published]),
    consultation_modes: 'in_person', consultation_fee: 50_000, booking_process: 'ora_coordinates'
  )
  provider.save!
  row[:locations].each_with_index do |(label, street, city, state), position|
    location = ProviderLocation.find_or_initialize_by(provider: provider, name: label)
    location.update!(address_line: street, city: city, state: state, country: 'Nigeria', phone: row[:phone], position: position)
  end
  provider.refresh_display_location!
  if row[:published]
    Provider::REQUIRED_CHECKS.each do |kind|
      check = ProviderVerification.find_or_initialize_by(provider: provider, kind: kind)
      check.update!(status: 'verified', source: 'manual', reference: kind == 'corporate' ? "RC #{row[:rc]}" : nil,
                    evidence: 'Demonstration record. Confirmed by hand during local onboarding; no register was called.',
                    verified_at: Time.current, verified_by: admin)
    end
  end
  provider.refresh_verification!
  Procedure.where(category: row[:specialty]).each do |procedure|
    listing = Listing.find_or_initialize_by(provider: provider, procedure: procedure)
    listing.update!(price: procedure.starting_price + (row[:name] == 'Meridian Care' ? 50000 : 0),
                    consultation_fee: 50_000, status: 'active')
  end
end
puts 'Ora demo catalog ready. Set ORA_ADMIN_PASSWORD when seeding to create or update the local admin account.'
