# 18 — Balance correctness unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/04`, `06`, `08`, `15`)

## What to build
Exhaustive `BalanceEngine` / balance-from-transactions unit tests covering the money-correctness invariants where bugs hide most. Assert balances through the public engine API given built transactions (issue 17 fixtures) — no SwiftData, no UI.

Cover: credit-card Expense increases that card's Liability and leaves the Account untouched; same-currency Transfer and credit-card bill payment net to zero on net worth (Account down + Liability/Account moved); **Backfill (informational) transactions are excluded from current balance**; Income increases the target Account; multi-transaction sums and empty→opening.

## Acceptance criteria
- [ ] Credit-card Expense → Liability up by amount, Account unchanged (test-case 04-01/04-03).
- [ ] Same-currency Transfer moves money, net worth unchanged; bill payment lowers Account and Liability equally (06-01/06-02).
- [ ] Backfill txn does NOT change current balance; current = opening + Σ of balance-affecting txns only (08-01/08-02).
- [ ] Income increases Account; Envelope remaining untouched by Income (15-01/15-02).
- [ ] Empty txns → opening; many-txn sum correct.
- [ ] Any case that reveals a real defect is wrapped/documented per the repo's known-defect convention (`XCTExpectFailure`/BUG-id) rather than left failing silently.

## Blocked by
- 17 — Test fixtures & builders
