# 25 — Signal engine unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/13`)

## What to build
`SignalEngine.signals(state)` tests: each deterministic rule fires on the right state and stays silent otherwise, with exact numbers (the model only phrases, never computes — ADR-0004).

## Acceptance criteria
- [ ] Envelope pace warning fires when spent fraction > month-elapsed fraction, and not otherwise (13-01).
- [ ] Quiet state → no signals (no false positives) (13-02).
- [ ] Goal behind-plan signal fires with the exact % behind (13-03).
- [ ] Projected-overspend signal fires on run-rate exceeding Allocation (13-05).
- [ ] All numbers in signals match engine math exactly — assert figures, not just presence (13-04).
- [ ] Date injected; table-driven across states.

## Blocked by
- 17 — Test fixtures & builders
