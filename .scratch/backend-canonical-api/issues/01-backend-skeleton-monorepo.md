# 01 — Backend skeleton & monorepo restructure

Status: ready-for-agent
Depends on: none
References: PRD, ADR-0016 (monorepo), ADR-0013

## Goal

Stand up the Rails backend app and reshape the repo into the monorepo layout so all later work has a home.

## Scope

- Restructure to `backend/ ios/ webapp/`. Move the existing `MoneyLover/`, `project.yml`, iOS-specific config into `ios/`. Keep shared `CONTEXT.md` and `docs/adr/` at the repo root. Update paths in root `CLAUDE.md` and any CI that references iOS paths.
- Create `backend/` as a Rails 7+ **API-only** app: PostgreSQL, Puma, Sidekiq, RSpec.
- Wire base conventions used by every endpoint:
  - **JSON-only**: reject non-JSON requests; default responses JSON.
  - **roar-rails** representers available.
  - **dry-validation** available for param contracts.
  - **Sidekiq** configured with Redis; a no-op scheduled job proves the wiring.
- Add CI with **path filters**: backend pipeline runs on `backend/**` changes; iOS pipeline runs on `ios/**`.
- Base error handling: structured JSON for 422 (validation), 401 (auth), 404, 500.

## Acceptance criteria

- `ios/` builds the existing app exactly as before (no behavior change; no version bump per ADR-0008 since iOS source is only moved).
- `backend/` boots, connects to Postgres + Redis, runs an empty RSpec suite green.
- A non-JSON request to any stub endpoint is rejected with a JSON error.
- CI runs backend and iOS pipelines independently by path.

## Tests

- Smoke request spec: a health endpoint returns JSON; a non-JSON `Accept`/body is rejected.
- Sidekiq wiring test: the no-op job enqueues and runs.
