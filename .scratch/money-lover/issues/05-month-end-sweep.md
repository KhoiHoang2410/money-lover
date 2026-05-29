# 05 — Month-end sweep

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
The month-end rollover. `BudgetEngine.applyMonthEnd`: each non-Reserve Envelope's positive leftover adds to the Reserve, an overspent Envelope deducts from the Reserve, then non-Reserve envelopes reset to their Allocation; the Reserve accumulates and does not reset. A sweep summary screen showing each envelope's contribution and the resulting Reserve change before applying.

## Acceptance criteria
- [ ] `applyMonthEnd` unit-tested: positive leftover → Reserve; overspend → Reserve deduction; non-Reserve reset to allocation; Reserve not reset.
- [ ] Sweep summary screen previews per-envelope deltas and total Reserve change.
- [ ] Applying the sweep updates Reserve and resets envelopes for the new month.

## Blocked by
- 04 — Envelopes & template
