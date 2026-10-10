# Ora

A Rails 8.1 application for a considered planned-care experience, with Turbo, Stimulus, SQLite locally, PostgreSQL in production, a responsive customer website, and a separate operations workspace.

## Open Ora

- Website: http://127.0.0.1:5000
- Operations: http://127.0.0.1:5000/admin
- Local admin: `admin@ora.local`, created when you seed with `ORA_ADMIN_PASSWORD` set.

The application was left running locally on port 5000. Use `bin/dev` to start it again. It binds to the loopback interface.

## Setup

Ruby 4.0.6 and Bundler were used for development. Dependencies are locked in `Gemfile.lock`. No Node build step is required.

```sh
bundle install
bin/rails db:prepare
bin/dev
```

To seed the fictional procedure and provider catalog and create a local admin:

```sh
ORA_ADMIN_PASSWORD='choose-a-private-password' bin/rails db:seed
```

The seed refuses to run in production and creates no patient records. Set `ORA_ADMIN_PASSWORD` to create or update the local admin password. Environment files are examples only; export variables in your shell. The password is never committed or shown on the sign-in page.

## Railway deployment

The Railway project builds from `Mtconcept/ora` on `main` and uses a PostgreSQL service. Set `RAILS_ENV=production`, `DATABASE_URL=${{Postgres.DATABASE_URL}}`, and `RAILS_MASTER_KEY` (the private contents of `config/master.key`) on the app service. Configure `bin/rails db:migrate` as its pre-deploy command and `/up` as its healthcheck path, then deploy the staged changes. `db:prepare` would also run the fictional seeds on a new database, so it must not be used in production. Keep the master key out of Git and logs.

The production database starts empty. The fictional local seeds intentionally refuse to run there; add real providers and procedures only after their details and verification have been approved. Production patient phone sign-in remains disabled until SMS verification is integrated, and a production admin account is not automatically created. A reachable website is therefore a deployment preview, not approval to accept real patients or financing applications.

## Working journeys

- Editorial home page, category browsing, Turbo search/filter/sort, procedure information, provider profiles and provider-specific prices.
- Affordability calculator with transparent assumptions and matching procedures.
- Passwordless local phone sign-in: random expiring codes, hashed verification, five-attempt limit, request throttling and eight-hour encrypted sessions.
- Guided intake with age checks, employment/income range, monthly comfort budget and recorded consent. Self-pay skips financial intake.
- Persisted saved procedures and My Care records, with chronological case events.
- Consultation requests, clinic confirmation, medical assessment, final treatment plan and updated-price handling.
- Manual financing outcomes: pending, pre-approved, partial, unavailable, offered, accepted and funded. No invented automated credit approvals.
- Upfront contributions and receipt confirmation. Patient acceptance is invalidated if price or financing terms change. Funded terms cannot be edited directly.
- Treatment-date requests, clinic confirmation, provider-supplied preparation and post-treatment reviews.
- Cancellations before funding; later changes route through the team.
- Support inbox and mobile early-access waitlist.
- Protected operations workspace: an overview of what needs attention, care search/filtering, editable care records, private team notes, assignments, audit events, provider/procedure publishing and pricing management.
- A care record is worked one phase at a time. Intake, consultation, medical review, financing and treatment each open only their own fields, and the workspace names the single next step and who it belongs to.
- An appointments diary reading every consultation and treatment date across the desk, upcoming and past.
- Provider onboarding runs as the same stepper: organisation, locations, services, verification, commercial, then review and publish. A provider stays an invisible draft until every stage is complete.
- Identifier first, documents second. Each stage offers the lookup it would use — business register, places, facility register, bank account — and, because none is connected, falls back to recording what operations confirmed by hand. A manual verification will not save without the evidence behind it.
- Ora owns the procedure catalogue: a procedure is described once, and each provider contributes only its own price, consultation fee, locations and availability. The catalogue page is read-only about who offers what.

## Try a full financing journey

1. Explore a procedure, view a provider, and choose **Explore payment options**.
2. Sign in, complete the guided form and request a weekday consultation.
3. In operations, open the care record. The stage rail opens on the phase that owns the next step. On **Consultation** record the clinic confirmation, then on **Medical review** record the provider's assessment and final price.
4. On **Financing**, enter a demo lender, sufficient approved amount (plus any agreed upfront contribution), term, monthly payment and full demonstration terms. Set financing to **Offered** and the journey stage to **Treatment plan**.
5. In the patient's My Care, open the plan and record demo acceptance.
6. In operations, record **Funded** after the simulated funding confirmation. Confirm any upfront contribution receipt separately.
7. The patient can request a treatment date. Operations can confirm the clinic booking and mark treatment complete after that date.
8. The patient can leave a review.

A second browser profile or private window is useful for switching between patient and admin. Admin sign-in intentionally rotates the session and signs out the patient in the same browser.

## Implementation

`CareCase` owns workflow checks and groups its ten statuses into the five phases the care record is worked through. `Provider` does the same for its six onboarding stages, and `Lookup` is the single boundary where a real business-register, places, facility-register or bank-verification adapter would be wired in — every stage above it already handles an unavailable source. `Listing` connects a procedure with a provider, its price, its consultation fee and where it is offered; a procedure a care journey depends on cannot be dropped from the provider offering it. All customer record access is scoped to the signed-in user. Operations access requires a separate admin session. Mutations use Rails CSRF protection; code verification and case updates use database locks. Templates escape user content. Financial and phone parameters are filtered from request logs.

The calculator is illustrative: treatment budget = monthly budget × term ÷ 1.12. The 12% figure is a total assumed financing charge, **not APR or an actual lender rate**. Actual offers are recorded separately by operations.

Seeded prices and providers are fictional demonstration data. Healthcare suitability and preparation instructions must come from the treating clinician.

## Checks

```sh
bin/rails test
bin/rails zeitwerk:check
RUBOCOP_CACHE_ROOT=tmp/rubocop bundle exec rubocop
bundle exec brakeman --no-pager -q
```

The integration suite covers public/admin rendering, Turbo frame responses, sign-in, expired codes, account isolation, intake validation, duplicate submissions, financing gates, acceptance, funding, treatment completion, saved care, waitlist, support and catalog edits. Browser checks cover customer sign-in, Turbo navigation, onboarding, mobile layouts/menu, and admin login/rendering.

JSON is constrained below version 3 because Rails 8.1's session metadata decoder uses the positional options-hash API. The app uses the compatible locked JSON 2.x dependency.

## External integrations still needed for a live launch

This is a functional **local MVP**, not a live healthcare or lending service.

- SMS delivery: production phone sign-in intentionally stays unavailable until a real verification adapter is configured. Demo OTP display is disabled in production.
- Financing partner APIs, underwriting/verification, executed lender agreements, disbursement and repayment reconciliation. This app currently records manual decisions and simulated acceptance/funding; it sends no money or lender requests.
- Provider verification lookups. `Lookup` currently reports every source as unavailable: CAC business register, places/maps, healthcare facility register and bank account verification. Onboarding records manual verification with evidence in the meantime, which is a deliberate stand-in and not a substitute for the real checks.
- Approved medical copy, clinic availability, and live booking notifications/reminders.
- Operational deployment, backups, shared rate-limit storage, monitoring, retention/deletion processes and the applicable privacy/consent documentation before handling real patient data.
- Native iOS/Android apps. The web app is responsive; the mobile page is a working waitlist.

## Design assets

The original hero image is `app/assets/images/ora-editorial.jpg`. It was created with the built-in image generation tool and saved locally. Its prompt and provenance are in `docs/design.md`. The website uses self-hosted DM Sans (SIL Open Font License, `docs/DM-Sans-OFL.txt`); the operations workspace uses self-hosted Inter in four weights (SIL Open Font License, `docs/Inter-OFL.txt`) — 400 for body copy, 500 for navigation and labels, 600 for headings and cards, 700 for page titles and key numbers. The serif face, used for the Ora wordmark and the website's headings, is the system Georgia font. No external font request is required at runtime. The customer site follows the Qoves landing style instead. `app/assets/stylesheets/landing.css` holds the component system used by the home, provider and treatment pages; `app/assets/stylesheets/site.css` re-themes the remaining customer pages (affordability, how it works, support, privacy, mobile, My Care, sign-in and the journey) onto the same palette and type. The operations workspace keeps its own Inter styling. The type stacks name the commercial PP Neue Montreal and F37 Zagma Mono first, so a licensed install is used when present, and otherwise fall back to self-hosted Geist and Geist Mono (SIL Open Font License, `docs/Geist-OFL.txt`). Admin workspace icons are Microsoft Fluent UI System Icons (`@fluentui/svg-icons` 1.1.341), self-hosted in `app/assets/images/icons/fluent/`; their MIT licence is in `docs/Fluent-UI-System-Icons-LICENSE.txt`.
