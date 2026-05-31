# 26 — Expense parser unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/14`)

## What to build
`ExpenseParser` post-processing tests against a **fake** Foundation Models returning fixed drafts. Verify the Swift side: amount/currency validation, the model never doing arithmetic, free-text note retention, and graceful handling of unparseable input. The on-device voice path itself (Speech + real model) stays manual/human-in-the-loop per the PRD.

## Acceptance criteria
- [ ] "bánh mì 40k cho 2 người" → amount 40,000 (the total), NOT divided; "cho 2 người" stays in the note (14-04).
- [ ] Amount/currency validated in Swift; any model-produced arithmetic ignored (14-01).
- [ ] Currency defaulting and Swift-side split math correct against fixed fake drafts.
- [ ] Unparseable/no-amount draft → empty amount, no garbage value, no crash (14-05).
- [ ] Parser is exercised with a fake model only — no Speech, no network, no real model.

## Blocked by
- 17 — Test fixtures & builders
