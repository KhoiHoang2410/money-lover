# 21 — Goal tracker unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/09`, `10`)

## What to build
`GoalTracker.progress(goal, asOf)` tests across schedule shapes with an injected date. Expected-by-today = cumulative Schedule due ≤ asOf; pct = actual ÷ expected − 1. Focus on the boundary cases that divide by zero or mishandle gap months.

## Acceptance criteria
- [ ] Expected-by-today honors a non-flat schedule with gap months — gap adds nothing, no interpolation (10-02).
- [ ] asOf before the first scheduled month → expected 0, no divide-by-zero, sane "not started" state (10-03).
- [ ] Exactly on plan → 0% (neither ahead nor behind) (10-04).
- [ ] Ahead → positive %, behind → negative %; asOf after target date → expected = full plan (10-01/10-05).
- [ ] Contribution raises actual and recomputes % consistently (09-02).
- [ ] Date injected for testability; table-driven across schedule shapes.

## Blocked by
- 17 — Test fixtures & builders
