# 06 — Same-currency transfer and credit-card bill payment

**Flow:** The owner moves money between own places (same currency) and pays a credit-card bill as a Transfer (Account down, Liability down) — never double-counted as an Expense.
**Source:** PRD #14,15; CONTEXT.md; ADR-0006 (BalanceEngine)
**Seed:** Accounts MBBank, VPBank, Savings; Credit cards VPBank Credit, MBBank Credit.

---

## TC-06-01 — Same-currency transfer moves money, net worth unchanged *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note MBBank balance M, Savings balance S, net worth N.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add tab → Transfer (same currency) | From = MBBank, To = Savings, amount 1,000,000 | Form accepts |
| 2 | Tap Save | — | MBBank = **M − 1,000,000₫**; Savings = **S + 1,000,000₫** |
| 3 | Read net worth | — | **N unchanged** (money moved, not spent) |
| 4 | Read Envelopes | — | No Envelope remaining changed |

- **Postconditions:** One Transfer persisted.

---

## TC-06-02 — Paying a credit-card bill lowers Account and Liability *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note VPBank Account A and VPBank Credit debt D (D > 0); net worth N.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add tab → Transfer | From = VPBank, To = VPBank Credit, amount = 2,000,000 | Form accepts a Liability as a transfer target |
| 2 | Tap Save | — | VPBank Account = **A − 2,000,000₫**; VPBank Credit debt = **D − 2,000,000₫** |
| 3 | Read net worth | — | **N unchanged** (Asset down and Debt down by the same amount) |

- **Postconditions:** One Transfer persisted.

---

## TC-06-03 — Bill payment is NOT an Expense *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Note all Envelope remainings.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Pay a credit-card bill as a Transfer | From = MBBank, To = MBBank Credit, 2,000,000 | No Envelope remaining changes — the payment is not double-counted against any budget |

- **Postconditions:** One Transfer persisted.

---

## TC-06-04 — Overpaying a card drives Liability below zero or is blocked *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** VPBank Credit debt D; choose payment > D.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Pay more than owed | amount = D + 500,000 | Either the card shows a credit (negative Liability) consistently in net worth, OR the app blocks with a clear message — never a silently wrong Debt total |

- **Postconditions:** Per spec decision; assert the chosen behavior, not "works".
