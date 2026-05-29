# 07 — Overview net worth

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
The Overview screen: total net worth, total Asset and total Debt (all VND via Valuator), with Holdings, Accounts, and Credit-card debt broken out. All amounts are **hidden by default** (`••••••`) with an eye toggle to reveal them. Gradient Rings visual (prototype reference).

## Acceptance criteria
- [ ] Net worth, Asset, Debt computed from balances + valuation; aggregation unit-tested.
- [ ] Holdings, Accounts (with native→VND), and Credit-card debt listed; debt shown negative.
- [ ] Amounts censored by default; eye toggle reveals/hides; censored state has a sensible VoiceOver label.
- [ ] Bottom inset reserved so the last row/Reconcile entry isn't hidden behind dock/FAB.

## Blocked by
- 02 — Expense & Income
- 06 — Valuation
