Rails.application.routes.draw do
  # JSON-only API (ADR-0013): every route defaults to the JSON format.
  defaults format: :json do
    # Liveness probe for load balancers / uptime monitors: 200 if the app boots.
    get "up" => "rails/health#show", as: :rails_health_check

    # JSON health check for clients: { "status": "ok" }.
    get "health" => "health#show", as: :health

    # Authenticated, tenant-scoped API surface (ADR-0014). The representative
    # resource here proves the authorization foundation; domain resources are
    # added under this namespace in issues 13–20.
    namespace :api do
      resources :identities, only: [ :show ]
    end
  end
end
