# Money Lover — Backend API

The canonical Rails API-only backend (ADR-0013). PostgreSQL is the source of
truth; this app exposes a JSON-only HTTP API. The pure money engine, auth, and
domain endpoints are added in later issues — this is the skeleton.

## Stack

- Rails 8 (`--api`), Ruby 3.2+
- PostgreSQL (integer minor units; no floats for money)
- Puma web server
- Sidekiq + Redis for background jobs
- RSpec for tests
- roar-rails representers for response shaping
- dry-validation for param contracts

## Conventions

- **JSON only.** Non-JSON request bodies (`415`) and non-JSON `Accept` headers
  (`406`) are rejected. See `app/controllers/concerns/json_only.rb`.
- **Structured errors.** `{ "error": { "code", "message", "details?" } }` for
  401 / 404 / 422 / 500. See `app/controllers/concerns/error_handling.rb`.
- **No money math in controllers or models** (added in later issues).

## Setup

Requires a running PostgreSQL and Redis.

```sh
bundle install
bin/rails db:prepare        # creates + loads the (currently empty) schema
bundle exec rspec           # green suite
bin/rails server            # boots Puma
bundle exec sidekiq         # background worker (needs Redis)
```

Configuration is via environment variables:

- `DATABASE_URL` — e.g. `postgres://postgres:postgres@localhost:5432`
- `REDIS_URL` — defaults to `redis://localhost:6379/0`

## API contract & conformance gate (ADR-0017)

The hand-maintained OpenAPI document at **`docs/api/openapi.yaml`** (repo root, one
level above `backend/`) is the source of truth for the JSON API. It *leads* the
implementation, not the other way around:

- **TypeScript types** are generated from it for `webapp/` to consume —
  `docs/api/generated/types.ts`. CI regenerates and fails if the checked-in
  types drift from the YAML.
- **Backend request specs** assert every live response (and accepted params)
  conforms to it, via `committee-rails`. A response whose shape diverges from
  the contract fails the suite (`spec/support/openapi_contract.rb`,
  `spec/requests/openapi_conformance_spec.rb` proves the gate bites).

### Asserting conformance in a request spec

`spec/support/openapi_contract.rb` includes the helper into every
`type: :request` example. After making a request, assert the response matches
the contract for its status:

```ruby
get "/accounts", headers: auth_headers
assert_conforms_to_contract(200)          # alias for assert_response_schema_confirm(200)
```

### Extending the OpenAPI contract

When you add or change an endpoint:

1. Edit `docs/api/openapi.yaml` **first** — add the path/operation, reuse the
   shared components (`Error`, `Pagination`, `MoneyMinorUnits`, the `bearerAuth`
   security scheme). Money is always integer minor units — never a float field.
2. Regenerate + lint the contract (Node, from `docs/api/`):
   ```sh
   cd docs/api
   npm ci            # first time only
   npm run lint      # redocly: the document is valid OpenAPI 3.x
   npm run generate  # refresh generated/types.ts (commit the result)
   npm run check     # generate + fail if generated/types.ts is stale
   ```
3. Implement the endpoint, then assert `assert_conforms_to_contract(<status>)`
   in its request spec.

CI runs `npm run lint` and `npm run check` on any `docs/api/**` change, and the
backend RSpec gate runs on `backend/**` *and* `docs/api/**` changes.

## Endpoints

- `GET /up` — liveness probe (Rails default).
- `GET /health` — JSON `{ "status": "ok" }`. First contract-tested endpoint.

## Background jobs

`NoopJob` (`app/sidekiq/noop_job.rb`) is a no-op Sidekiq worker that proves the
Redis wiring; see `spec/sidekiq/noop_job_spec.rb`.
