Rails.application.routes.draw do
  get "/", to: "admin/sessions#entry", constraints: { host: "admin.myora.care" }, as: :admin_entry
  root "pages#home"
  get "robots.txt", to: "pages#robots"
  get "how-it-works", to: "pages#how", as: :how
  get "affordability", to: "pages#affordability"
  get "mobile", to: "pages#mobile"
  get "privacy", to: "pages#privacy"
  get "support", to: "pages#support"
  post "support", to: "pages#create_support"
  post "waitlist", to: "pages#waitlist"
  resources :procedures, only: [ :index, :show ], param: :slug do
    post :save, on: :member
  end
  resources :providers, only: [ :index, :show ], param: :slug
  get "sign-in", to: "sessions#new", as: :sign_in
  post "sign-in", to: "sessions#create"
  get "verify", to: "sessions#verify"
  post "verify", to: "sessions#confirm"
  delete "sign-out", to: "sessions#destroy", as: :sign_out
  get "begin", to: "journey#start", as: :start_journey
  get "journey/:step", to: "journey#show", as: :journey
  post "journey/:step", to: "journey#update"
  get "my-care", to: "cases#index", as: :my_care
  resources :cases, only: [ :show, :create ] do
    get :consultation, on: :member
    post :book_consultation, on: :member
    get :plan, on: :member
    post :accept_terms, on: :member
    post :book_treatment, on: :member
    post :cancel, on: :member
    post :review, on: :member
    post :request_revision, on: :member
  end
  namespace :admin do
    get "sign-in", to: "sessions#new", as: :sign_in
    post "sign-in", to: "sessions#create"
    get "two-factor", to: "sessions#two_factor", as: :two_factor
    post "two-factor", to: "sessions#confirm_two_factor"
    delete "sign-out", to: "sessions#destroy", as: :sign_out
    root "dashboard#index"
    resources :users do
      post :suspend, on: :member
      post :reactivate, on: :member
      delete :deactivate, on: :member
    end
    resources :customers, only: [ :index, :show ]
    resources :cases, only: [ :index, :show, :update ]
    get "appointments", to: "appointments#index"
    resources :providers, only: [ :index, :new, :create ], param: :slug do
      member do
        get "stage/:stage", action: :stage, as: :stage
        patch "stage/:stage", action: :update_stage
        post :lookup
        post :locations, action: :add_location
        delete "locations/:location_id", action: :remove_location, as: :location
        post :checks, action: :record_check
        post :publish
      end
    end
    get "catalog/:kind", to: "catalog#index", as: :catalog
    get "catalog/:kind/new", to: "catalog#new", as: :new_catalog
    post "catalog/:kind", to: "catalog#create"
    get "catalog/:kind/:id/edit", to: "catalog#edit", as: :edit_catalog
    patch "catalog/:kind/:id", to: "catalog#update", as: :update_catalog
    get "inbox", to: "dashboard#inbox"
    patch "inbox/:id", to: "dashboard#resolve", as: :resolve
    get "settings", to: "settings#index"
    get "settings/team", to: "settings#team", as: :settings_team
  end
  get "up" => "rails/health#show", as: :rails_health_check
end
