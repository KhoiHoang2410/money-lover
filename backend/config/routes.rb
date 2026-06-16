Rails.application.routes.draw do
  # JSON-only API (ADR-0013): every route defaults to the JSON format.
  defaults format: :json do
    # Liveness probe for load balancers / uptime monitors: 200 if the app boots.
    get "up" => "rails/health#show", as: :rails_health_check

    # JSON health check for clients: { "status": "ok" }.
    get "health" => "health#show", as: :health
  end
end
