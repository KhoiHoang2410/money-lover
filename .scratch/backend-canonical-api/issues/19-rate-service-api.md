# 19 — RateService: fetch jobs, parsers, overrides & rates API

Status: ready-for-agent
Depends on: 02, 04, 08
References: PRD, ADR-0013 (supersedes ADR-0003 client fetch), CONTEXT.md (Rate)

## Goal

Fetch and cache global market rates on a schedule, support per-user overrides, and expose rates to clients.

## Scope

- `rates` global table (key e.g. `fx.USD`, `fx.SGD`, `gold`, `stock.<TICKER>`; value; fetched-at; source) + `rate_overrides` per user.
- **Sidekiq scheduled jobs** fetch FX, SJC gold, and HOSE stock; **payload parsers** convert upstream responses to integer-safe values. On failure, serve last cached value flagged **stale**.
- **Override resolution** (the resolved-rate provider consumed by Valuator, issue 08): a user's override wins for that user only; otherwise the global cached value; otherwise stale fallback.
- Endpoints (extend OpenAPI YAML + conformance): `GET /rates` (resolved for current user), `PUT /rates/:key/override`, `DELETE /rates/:key/override`.

## Acceptance criteria

- Scheduled job populates/refreshes global rates; failure path serves stale without crashing.
- A user's override affects only their valuations; another user sees the global value.
- Responses conform to the OpenAPI YAML.

## Tests

- Parser unit tests against **captured upstream fixtures** (no live network).
- Override resolution unit tests (override / global / stale fallback).
- Request specs: get resolved rates, set/clear override, per-user isolation; conformance.
