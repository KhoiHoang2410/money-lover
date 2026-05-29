# 12 — Backfill

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Backfill mode: log a forgotten past Transaction flagged **informational** (`affectsBalance == false`) so it appears in history and reports but does NOT change the Current balance (which is already correct). A backfill entry screen with a past date.

## Acceptance criteria
- [ ] `BalanceEngine` excludes informational (Backfill) transactions from Current balance; unit-tested.
- [ ] Backfill screen records a past-dated transaction marked informational.
- [ ] The backfilled txn shows in history/day-detail but leaves balances unchanged.

## Blocked by
- 02 — Expense & Income
