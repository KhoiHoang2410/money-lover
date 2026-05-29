# 02 — Expense & Income

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Manual Expense and Income entry that moves balances. Add the Transaction domain type and Records, and `BalanceEngine` computing `Current balance = Opening + Σ balance-affecting Transactions`. Input → Expense form (numeric keypad, pick source, note) and Income form (into an Account). An Expense on a Credit card increases that Liability; on an Account/debit it reduces the Account. Current balances update on the source list. Money correctness per `docs/guidelines/agent-playbook.md`.

## Acceptance criteria
- [ ] `BalanceEngine.current(opening, txns)` unit-tested for Expense/Income on Account and on Credit-card (liability) plus multi-txn sums.
- [ ] Manual Expense saves with amount (numeric `format:`, decimal pad), source, note; balance updates.
- [ ] Income increases the chosen Account.
- [ ] Credit-card Expense raises the card's Liability, touches no Account.
- [ ] Transaction Record ⇄ domain mapping unit-tested.

## Blocked by
- 01 — Foundation & Sources
