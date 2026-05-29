# 03 — Transfers

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Transfer between the owner's own places, in three modes: same-currency; cross-currency (enter amount-out, amount-in, manual Rate → app computes the **Fee** = out×rate − in, in the destination currency); and pay-credit-card (Account ↓, Liability ↓). A Transfer is never an Expense/Income. Cross-currency Transfers use the manual rate, not the auto-fetched valuation rate (ADR-0003).

## Acceptance criteria
- [ ] Same-currency Transfer moves money between two sources; balances update.
- [ ] Cross-currency Transfer computes and stores Fee = out×rate − in; unit-tested.
- [ ] Paying a credit-card bill lowers both the Account and the card Liability, and is not counted as an Expense.
- [ ] Transfer never appears in envelope spending.

## Blocked by
- 02 — Expense & Income
