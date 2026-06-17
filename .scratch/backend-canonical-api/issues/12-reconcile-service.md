# 12 — ReconcileService (pure, golden-tested)

Status: ready-for-agent
Depends on: 03, 04, 07
References: PRD, ADR-0015, CONTEXT.md (Reconcile, Adjustment, Current balance)

## Goal

Given submitted real balances, derive the Adjustment per source needed to make current balance equal reality.

## Scope

- Pure module: for each source, Adjustment amount = real balance − current balance (from BalanceEngine). Produces zero, positive, or negative adjustments; carries description + optional envelope assignment slot.
- No persistence here; the action endpoint (issue 17) wraps this in a createable Reconciliation that writes the Adjustment transactions atomically.

## Acceptance criteria

- Reproduces reconcile golden fixtures byte-identically.
- No adjustment produced when real == current.

## Tests

- Golden-vector spec for adjustment derivation (over/under/exact).
- Unit: multi-source reconcile produces independent adjustments.
