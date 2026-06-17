# 16 — Goals API (+ contributions action)

Status: ready-for-agent
Depends on: 02, 11, 14
References: PRD, ADR-0017, ADR-0007, CONTEXT.md (Goal, Contribution, Schedule, status)

## Goal

CRUD for goals plus the contribution action and progress data.

## Scope

- `goals` schema (user-scoped): name, icon, target, funding window (start/end month), schedule (month → planned).
- Endpoints (extend OpenAPI YAML + conformance):
  - CRUD: `GET/POST/PATCH/DELETE /goals`, returning balance (Σ contributions) and GoalTracker progress (expected-by-today, per-line status, shortfall).
  - **Contribution**: `POST /goals/:id/contributions` → creates a `.transfer` from a VND Account to the Goal, atomically debiting the Account and crediting the Goal (net worth unchanged). VND-only; reject foreign-currency funding.
- dry-validation contracts (schedule shape, VND account, positive amounts).

## Acceptance criteria

- Goal read includes correct balance and per-line status/shortfall (GoalTracker).
- A Contribution moves real money atomically and leaves net worth unchanged (verified via NetWorth).
- Non-VND funding rejected.
- Responses conform to the OpenAPI YAML.

## Tests

- Request specs: CRUD, contribution happy path + atomicity, non-VND rejection, status/shortfall correctness.
- Authorization, validation, conformance.
