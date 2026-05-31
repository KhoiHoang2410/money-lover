# 03 — Add expense

**Flow:** The owner logs a manual Expense (amount, source, envelope, note); it reduces the Account and the Envelope remaining.
**Source:** PRD #10,13,20,39; ui-test-scenarios.md S4; ADR-0006 (BalanceEngine, BudgetEngine)
**Seed:** Cash Account; Envelopes Food, Rent, Transport, Fun, Reserve.

---

## TC-03-01 — Cash expense reduces Account and Envelope *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** AddExpenseUITests.testAddExpenseSavesAndReturns
- **Preconditions:** App seeded; note Cash balance and Food remaining.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add tab → "Add transaction" | — | Expense entry shown |
| 2 | Type amount | 45000 | Field accepts 45,000₫ |
| 3 | Set From, Envelope | From = Cash, Envelope = Food | Selections reflected |
| 4 | Tap Save | — | Dismisses to Add hub; **Cash − 45,000₫**; **Food remaining − 45,000₫** |

- **Postconditions:** One Expense persisted on Cash/Food.

---

## TC-03-02 — Save disabled until amount AND source set *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** AddExpenseUITests.testSaveDisabledWithoutAmount
- **Preconditions:** Expense entry open, fields empty.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Leave amount empty, no source | — | Save disabled |
| 2 | Type amount only | 45000 | Save still disabled (no source) |
| 3 | Set source only, clear amount | From = Cash | Save still disabled |
| 4 | Set both | 45000 + Cash | Save enabled |

- **Postconditions:** Nothing saved.

---

## TC-03-03 — Zero / empty amount rejected *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Expense entry open; From = Cash, Envelope = Food.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Type amount 0 | 0 | Save disabled (no zero-value expense) |
| 2 | Type non-numeric | "abc" | Field rejects / parses to no value; Save disabled |

- **Postconditions:** Nothing saved.

---

## TC-03-04 — No float drift on awkward amounts *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Expense entry; From = Cash, Envelope = Food; note Cash balance.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save two expenses | 0.10 + 0.20 (in a sub-unit currency context) | Combined effect is exactly 0.30, never 0.30000004 — minor-units, no float drift |
| 2 | Read Cash after both | — | Balance reduced by exactly the integer-minor-unit sum |

- **Postconditions:** Two expenses persisted.

---

## TC-03-05 — Overspending an Envelope is allowed, remaining goes negative *(Edge)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Pick an Envelope with small remaining (e.g. Transport); note its remaining R.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save an expense larger than R | amount = R + 50,000 | Save succeeds; Envelope remaining = **−50,000₫** (negative, not clamped to 0) |
| 2 | Observe nudge | — | An input-time over-pace nudge may surface (PRD #32) but does not block the save |

- **Postconditions:** Envelope remaining negative until month-end sweep.

---

## TC-03-06 — Note free-text preserved *(Positive)*

- **Priority:** Low
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Expense entry; From = Cash, Envelope = Food.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter note, save | "bánh mì cho 2 người" | Saved expense carries the exact note text; no separate people-count field created |

- **Postconditions:** One expense persisted with the note.
