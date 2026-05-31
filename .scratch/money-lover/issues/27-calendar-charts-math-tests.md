# 27 — Calendar / trend / charts math unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/17`, `18`)

## What to build
Unit tests for the pure math behind the Calendar and Charts: per-day net, trend series, per-Envelope spending buckets, range windows, average-per-day scaling, and the insufficient-history refusal. UI rendering stays in the XCUITest slice (issue 28).

## Acceptance criteria
- [ ] Per-day net = sum of that day's balance-affecting txns; empty day → 0, no carryover (17-01).
- [ ] Backfill informational txns handled per the spec's documented rule for day-net (17-05).
- [ ] Range windows (7d / 30d / 6m) select the correct transactions (18-02).
- [ ] 30d & 6m series scaled to average-per-day so ranges are comparable (18-02 / PRD #57).
- [ ] Insufficient history for a range → an explicit refusal signal, not partial/misleading data (18-03).
- [ ] Per-Envelope bucket math scales each row to its own max (18-04).

## Blocked by
- 17 — Test fixtures & builders
