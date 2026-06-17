# 15 — Envelopes API (+ starter envelopes, allocation template)

Status: ready-for-agent
Depends on: 02, 10, 14
References: PRD, ADR-0017, CONTEXT.md (Envelope, Allocation, Allocation template, Starter envelopes, Reserve)

## Goal

CRUD for envelopes plus the two seeding actions and per-month budget state.

## Scope

- `envelopes` schema (user-scoped): name, icon, monthly allocation, reserve flag, optional weekly/monthly caps, carried; **per-month allocation history** (per issue 10's decision).
- Endpoints (extend OpenAPI YAML + conformance):
  - CRUD: `GET/POST/PATCH/DELETE /envelopes`, returning spent/remaining for the current month (BudgetEngine).
  - **Starter envelopes** seeding → a createable resource; idempotent on existing names (case-insensitive, trimmed); designates Reserve only if none exists.
  - **Allocation template**: save template + apply to a month → a createable resource that seeds that month's allocations.
- Exactly one Reserve invariant enforced.
- dry-validation contracts (allocation ≥ 0, caps optional, one reserve).

## Acceptance criteria

- Envelope read includes correct spent/remaining for the user's current month/timezone.
- Starter seeding does not duplicate existing-by-name envelopes.
- Applying a template seeds the month's allocations correctly.
- Responses conform to the OpenAPI YAML.

## Tests

- Request specs: CRUD, starter idempotency, template apply, reserve uniqueness.
- Authorization, validation, conformance.
