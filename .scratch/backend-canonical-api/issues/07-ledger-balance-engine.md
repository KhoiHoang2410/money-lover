# 07 — Ledger / BalanceEngine (pure, golden-tested)

Status: ready-for-agent
Depends on: 03, 04
References: PRD, ADR-0015, CONTEXT.md (Current balance, Backfill)

## Goal

The single authority for a source's current balance: opening + Σ balance-affecting transactions.

## Scope

- Pure Ruby module (no Rails/DB) computing **current balance per source** from an opening balance and a transaction list, honoring each kind's balance effect:
  - Expense: Account/debit ↓; credit-card → Liability ↑.
  - Income: Account ↑.
  - Transfer: source ↓, destination ↑ (credit-card bill payment, cross-currency).
  - Invest: Account ↔ Holding money leg.
  - Adjustment: applies the reconcile delta.
- **Backfill** semantics at the engine level: a backfilled transaction affects history but the opening restatement keeps current balance unchanged (the engine is given the restated opening; the atomic write lives in issue 14's transaction endpoint).
- Operates entirely in integer minor units via the Money type (issue 04).

## Acceptance criteria

- Reproduces the golden fixtures (issue 03) for balances byte-identically.
- Invariant holds for every fixture: current balance = opening + Σ transactions.

## Tests

- Golden-vector spec over the balance fixtures.
- Unit edge cases: credit-card expense increases liability; cross-currency transfer applies destination amount, not source amount.
