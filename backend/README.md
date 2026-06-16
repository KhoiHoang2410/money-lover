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

## Endpoints

- `GET /up` — liveness probe (Rails default).
- `GET /health` — JSON `{ "status": "ok" }`.

## Background jobs

`NoopJob` (`app/sidekiq/noop_job.rb`) is a no-op Sidekiq worker that proves the
Redis wiring; see `spec/sidekiq/noop_job_spec.rb`.
