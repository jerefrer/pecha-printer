Rails.application.routes.draw do
  resources :pdfs, only: [ :new, :create, :update ] do
    get "download", on: :member
    get "edit", on: :member, to: "pdfs#new"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "pdfs#new"

  # Catch-all route for unknown URLs
  match "*path", to: redirect("/"), via: :all
end
