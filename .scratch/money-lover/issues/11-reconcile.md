# 11 — Reconcile → Adjustment

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Reconcile mode ("update balance"). The owner re-enters each source's real balance; `ReconcileService` compares to the computed Current balance and produces an **Adjustment** Transaction for any difference (with a description and an Envelope assignment). Equal balances produce no Adjustment.

## Acceptance criteria
- [ ] `ReconcileService.adjustment(source, realBalance)` unit-tested: positive and negative diffs produce a correctly-signed Adjustment; equal → nil.
- [ ] Reconcile screen lets the owner enter the real balance per source and shows the diff.
- [ ] Each diff is recorded as an Adjustment carrying a description and an Envelope.

## Blocked by
- 02 — Expense & Income
- 04 — Envelopes & template
