# 24 — Reconcile unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/07`)

## What to build
`ReconcileService.adjustment(source, realBalance)` tests: produce an Adjustment for the diff between computed current balance and the entered real balance; nil when equal.

## Acceptance criteria
- [ ] Higher real balance → positive Adjustment of the correct magnitude (07-01).
- [ ] Lower real balance → negative Adjustment (07-02).
- [ ] Equal balance → nil, no Adjustment (07-03).
- [ ] Adjustment carries its description and Envelope — never an uncategorized silent plug (07-05).
- [ ] Reconciling multiple sources yields one Adjustment per changed source, none for unchanged (07-04).

## Blocked by
- 17 — Test fixtures & builders
