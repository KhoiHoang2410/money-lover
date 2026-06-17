# 20 — SignalEngine & signals API

Status: ready-for-agent
Depends on: 02, 10, 11, 14, 19
References: PRD, ADR-0004 (paused — deterministic only), CONTEXT.md (Signal, Recommendation)

## Goal

Compute deterministic spending/goal signals on the backend and return them as plain text to clients.

## Scope

- **SignalEngine** (pure, ported from Swift): envelope pace (spent vs fraction of month elapsed), projected overspend, goal delay, shrinking Reserve, unusually large Expense. Deterministic — no model, no LLM.
- Returns plain-text signals (the "Recommendation" phrasing layer is deferred; return the deterministic text directly).
- Endpoint (extend OpenAPI YAML + conformance): `GET /signals` for the current user, computed over their ledger/budgets/goals in their timezone.

## Acceptance criteria

- Signals match golden-tested expectations for known ledgers.
- No AI/LLM/voice involved (ADR-0004 paused).
- Response conforms to the OpenAPI YAML.

## Tests

- Golden-vector spec for SignalEngine over known states.
- Request spec: `GET /signals` returns the expected signals; authorization; conformance.
