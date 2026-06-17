# 17 — Reconcile action API

Status: ready-for-agent
Depends on: 02, 12, 14
References: PRD, ADR-0017, CONTEXT.md (Reconcile, Adjustment)

## Goal

Expose Reconcile as a createable, auditable action that produces Adjustment transactions.

## Scope

- Endpoint (extend OpenAPI YAML + conformance): `POST /reconciliations` — body submits real balances per source.
- Server runs ReconcileService (issue 12), then **atomically** writes the resulting Adjustment transactions (issue 14 semantics) in one DB transaction.
- Response represents the created Reconciliation and the Adjustments produced (auditable record).
- dry-validation contract (source ids belong to user, balances are integer minor units).

## Acceptance criteria

- Submitting real balances creates exactly the right Adjustments (zero when already correct).
- All-or-nothing: a failure writes no adjustments.
- Cross-user source ids are rejected.
- Response conforms to the OpenAPI YAML.

## Tests

- Request specs: over/under/exact reconcile, atomic failure, authorization, conformance.
