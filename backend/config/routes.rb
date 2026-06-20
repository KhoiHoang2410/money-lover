Rails.application.routes.draw do
  # JSON-only API (ADR-0013): every route defaults to the JSON format.
  defaults format: :json do
    # Liveness probe for load balancers / uptime monitors: 200 if the app boots.
    get "up" => "rails/health#show", as: :rails_health_check

    # JSON health check for clients: { "status": "ok" }.
    get "health" => "health#show", as: :health

    # Public auth surface (ADR-0014, issue 06): mint/rotate/revoke the tokens
    # the rest of the API requires. Unauthenticated by design.
    post "auth/register" => "auth#register", as: :auth_register
    post "auth/login"    => "auth#login",    as: :auth_login
    post "auth/refresh"  => "auth#refresh",  as: :auth_refresh
    post "auth/logout"   => "auth#logout",   as: :auth_logout

    # Authenticated, tenant-scoped API surface (ADR-0014). The representative
    # resource here proves the authorization foundation; domain resources are
    # added under this namespace in issues 13–20.
    namespace :api do
      resources :identities, only: [ :show ]

      # Money sources — Accounts, Credit cards, Holdings (issue 13). Full CRUD,
      # tenant-scoped; non-CRUD actions on sources are added in later issues.
      resources :sources, only: [ :index, :show, :create, :update, :destroy ]

      # Transactions — Expense / Income / Transfer / Invest / Adjustment
      # (issue 14). Full CRUD, tenant-scoped; the write path is atomic (a
      # cross-currency transfer, a backfill restatement, and an invest oversell
      # guard each commit or roll back as one).
      resources :transactions, only: [ :index, :show, :create, :update, :destroy ]

      # Envelopes — named virtual budget buckets (issue 15). Full CRUD,
      # tenant-scoped; each read returns the month's spent/remaining (BudgetEngine).
      resources :envelopes, only: [ :index, :show, :create, :update, :destroy ]

      # Starter-envelope seeding (createable, idempotent on existing names) and
      # Allocation-template apply (createable, seeds a month's allocations) —
      # singular resources: one action each (POST), no id in the path.
      resource :starter_envelopes, only: [ :create ]
      resource :allocation_template, only: [ :create ], controller: "allocation_template"
    end

    # Rate service (issue 19): resolved rates for the current User + per-User
    # override management. Paths are unprefixed to match the OpenAPI contract
    # (docs/api/openapi.yaml); controllers live under Api:: to reuse the
    # tenant-scoped BaseController. The `key` constraint allows the dots in
    # rate keys (e.g. fx.USD, stock.VNM) that Rails would otherwise treat as a
    # format separator.
    scope module: :api do
      get "rates" => "rates#index", as: :rates
      put "rates/:key/override" => "rates#set_override",
          as: :rate_override, constraints: { key: %r{[^/]+} }
      delete "rates/:key/override" => "rates#clear_override",
             constraints: { key: %r{[^/]+} }
    end
  end
end
