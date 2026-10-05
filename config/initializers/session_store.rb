Rails.application.config.session_store :cookie_store,
  key: "_ora_session",
  expire_after: 8.hours,
  same_site: :lax,
  secure: Rails.env.production?,
  httponly: true
