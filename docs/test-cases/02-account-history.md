# 02 — Account history

**Flow:** The owner drills into one Account to see its transactions.
**Source:** PRD #8; ui-test-scenarios.md S3 (was BUG-001)
**Seed:** MBBank Account with seeded transactions.

---

## TC-02-01 — Tap an account row opens its history *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** OverviewPrivacyUITests.testTapAccountOpensHistory
- **Preconditions:** Overview open with seed data.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the MBBank account row | — | Account History screen pushes; nav title "MBBank" |
| 2 | Read the list | — | MBBank's transactions are listed (not another account's) |

- **Postconditions:** None.

---

## TC-02-02 — Holding row opens valuation history *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Overview open; Gold SJC present.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the Gold SJC row | — | Detail pushes showing quantity (chỉ) and its current VND valuation |

- **Postconditions:** None.

---

## TC-02-03 — Account with no transactions shows empty state *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** An Account with only an Opening balance and no transactions (e.g. Savings if seeded empty).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap that account row | — | History pushes; shows an empty-state message (not a blank/crashing list); balance equals Opening |

- **Postconditions:** None.
