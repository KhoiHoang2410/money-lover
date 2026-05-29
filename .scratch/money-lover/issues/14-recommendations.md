# 14 — Recommendations

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Rule-based Recommendations (ADR-0004). `SignalEngine` computes Signals deterministically in Swift — envelope pace, projected overspend, goal behind-plan, Reserve trend, unusually-large Expense. Surfaced as an input-time nudge and as an Advice summary screen (reached from Config). The on-device model may only phrase a Signal into friendly text; a template + icon is the fallback. The model never decides whether spending is too high.

## Acceptance criteria
- [ ] `SignalEngine.signals(state)` unit-tested per rule (fires on the right state, silent otherwise); numbers exact.
- [ ] Input-time nudge appears when relevant (e.g. envelope nearly spent late in the month).
- [ ] Advice screen lists current Signals, color + icon coded.
- [ ] No analysis is delegated to the LLM.

## Blocked by
- 04 — Envelopes & template
- 08 — Goals
