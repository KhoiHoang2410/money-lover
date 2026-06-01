# 20 — Budget engine unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/11`, `12`)

## What to build
`BudgetEngine` tests for envelope remaining and `applyMonthEnd`. Cover remaining math, overspend, template application, and the full month-end sweep semantics including the Reserve's special handling.

## Acceptance criteria
- [ ] remaining = Allocation − spent; overspend → negative remaining, not clamped (11-01/11-03).
- [ ] Allocations independent of any single Income (11-02).
- [ ] Month-end: positive leftover → Reserve; overspend → Reserve deduction; mixed leftovers/overspends net correctly (12-01/12-02/12-03).
- [ ] Non-Reserve envelopes reset to Allocation; Reserve accumulates and does NOT reset (12-04).
- [ ] Sweep is idempotent for the same month boundary — running twice does not double-apply (12-05).
- [ ] Template application sets allocations; sum of allocations independent of income.

## Blocked by
- 17 — Test fixtures & builders
