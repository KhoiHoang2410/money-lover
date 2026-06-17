# 10 — BudgetEngine + month-end sweep design (pure, golden-tested)

Status: ready-for-agent
Depends on: 03, 04, 07
References: PRD, ADR-0015, CONTEXT.md (Envelope, Allocation, Reserve, Reserve sweep)

## Goal

Compute envelope spent/remaining per month, apply allocations and caps, and handle Reserve carry/sweep — and resolve the deferred month-end mechanism.

## Scope

- Pure module: per-month **spent** (Σ expenses assigned to the envelope in that month from the ledger), **remaining** = allocation − spent, weekly/monthly cap checks.
- **Reserve sweep**: at month-end each non-Reserve envelope's leftover (allocation − spent) moves to the Reserve — positive adds, overspend (negative) deducts; the Reserve accumulates and does not reset.
- **Resolve the deferred design decision** (PRD Further Notes): choose *derived-on-read from stored per-month allocation snapshots* vs *stateful per-user-timezone job*. Recommendation: derived-on-read (idempotent, no timezone cron). Whichever is chosen, the schema must store **per-month allocation history** and use `User.timezone` for boundaries. Record the choice in an ADR if it turns out to be hard-to-reverse.

## Acceptance criteria

- Reproduces budget/sweep golden fixtures byte-identically (including overspent-envelope deducting from Reserve).
- Month boundaries computed in the user's timezone.
- The chosen sweep mechanism is idempotent (recomputing/replaying does not double-apply).

## Tests

- Golden-vector spec for spent/remaining/caps and reserve sweep.
- Unit: overspend deducts Reserve; cap thresholds; timezone boundary case (transaction near midnight month-end).
