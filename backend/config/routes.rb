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

      # Reconcile action (issue 17) — POST a set of re-entered real balances;
      # the server writes the resulting Adjustment transactions atomically and
      # returns the auditable Reconciliation (CONTEXT.md "Reconcile"/"Adjustment").
      resources :reconciliations, only: [ :create ]

      # Goals — long-term savings targets (issue 16). Full CRUD, tenant-scoped.
      # A read returns the Goal's live balance (Σ Contributions) and GoalTracker
      # progress/status/shortfall. The nested contributions action funds a Goal
      # from a VND Account, recorded atomically as a Transfer (ADR-0007).
      resources :goals, only: [ :index, :show, :create, :update, :destroy ]
      post "goals/:goal_id/contributions" => "goals#create_contribution",
           as: :goal_contributions

      # Net worth & report-data (issue 18) — read-only aggregates derived on
      # read by the pure engines (NetWorthEngine / BudgetEngine / GoalTracker),
      # all in the base currency VND. Net worth is asset/debt/net; the report
      # endpoints shape the data behind the clients' charts.
      get "net_worth" => "reports#net_worth", as: :net_worth
      get "reports/spending_trends" => "reports#spending_trends", as: :report_spending_trends
      get "reports/envelope_distribution" => "reports#envelope_distribution",
          as: :report_envelope_distribution
      get "reports/goal_progress" => "reports#goal_progress", as: :report_goal_progress
      get "reports/net_worth_history" => "reports#net_worth_history", as: :report_net_worth_history
    end

    # Rate service (issue 19): resolved rates for the current User + per-User
    # override management. Paths are unprefixed to match the OpenAPI contract
    # (docs/api/openapi.yaml); controllers live under Api:: to reuse the
    # tenant-scoped BaseController. The `key` constraint allows the dots in
    # rate keys (e.g. fx.USD, stock.VNM) that Rails would otherwise treat as a
    # format separator.
    scope module: :api do
      # Signals (issue 20): the deterministic spending/goal Signals computed for
      # the current User. Unprefixed to match the OpenAPI contract; the
      # controller lives under Api:: to reuse the tenant-scoped BaseController.
      get "signals" => "signals#index", as: :signals

      get "rates" => "rates#index", as: :rates
      put "rates/:key/override" => "rates#set_override",
          as: :rate_override, constraints: { key: %r{[^/]+} }
      delete "rates/:key/override" => "rates#clear_override",
             constraints: { key: %r{[^/]+} }
    end
  end
end
