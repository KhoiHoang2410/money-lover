# 04 — Credit-card expense

**Flow:** The owner spends on a Credit card; the card's Liability rises at purchase time and no Account is touched.
**Source:** PRD #12; CONTEXT.md (Credit card = Liability); ADR-0006 (BalanceEngine)
**Seed:** Credit cards VPBank Credit, MBBank Credit; Accounts incl. VPBank, MBBank.

---

## TC-04-01 — Credit-card spend increases Liability, Account untouched *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** App seeded; note VPBank Credit debt D and VPBank Account balance A.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Calendar + → Expense | amount 500,000 | Field accepts |
| 2 | Set source = VPBank Credit, Envelope = Fun | — | Credit card selectable as a spend source |
| 3 | Tap Save | — | VPBank Credit debt = **D + 500,000₫**; VPBank Account = **A unchanged** |
| 4 | Open Overview | — | Debt total rose by 500,000₫; Asset total unchanged |

- **Postconditions:** One credit expense persisted on VPBank Credit.

---

## TC-04-02 — Credit spend reduces Envelope remaining like any expense *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note Fun remaining R.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save a credit-card expense to Fun | 500,000 on VPBank Credit | Fun remaining = **R − 500,000₫** (budget tracks the spend even though no Account moved) |

- **Postconditions:** One credit expense persisted.

---

## TC-04-03 — Credit spend is NOT counted as Asset reduction *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Note net worth N (revealed).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save a credit-card expense | 500,000 on MBBank Credit | Net worth = **N − 500,000₫** because Debt rose, NOT because any Account fell |
| 2 | Verify no Account changed | — | Every Account balance identical to before |

- **Postconditions:** One credit expense persisted.
