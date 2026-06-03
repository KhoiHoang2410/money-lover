# 11 — Envelope budgeting

**Flow:** The owner defines Envelopes with Allocations, divides money into buckets, and watches remaining as Expenses are assigned.
**Source:** PRD #17,18,19,20,21,24; ADR-0006 (BudgetEngine); CONTEXT.md (Envelope, Allocation, Reserve)
**Seed:** Envelopes Food, Rent, Transport, Fun, Reserve (default Reserve).

---

## TC-11-01 — Remaining = Allocation − spent *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** EnvelopesUITests.testExpenseReducesEnvelopeRemainingAndPersists — an expense reduces Food's remaining cross-tab, survives relaunch (EFFECT-CONTRACT.md)
- **Preconditions:** Note Food Allocation A; no spend yet this month (or known spent S).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add an Expense to Food | 100,000 | Food remaining = **A − (S + 100,000)** |
| 2 | Add another to Food | 50,000 | Food remaining drops by a further 50,000 |

- **Postconditions:** Two expenses persisted.

---

## TC-11-02 — Allocations are independent of any single Income *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note sum of Allocations across all Envelopes.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Record an Income | 5,000,000 to MBBank | No Envelope Allocation or remaining changes — budgeting is over total available money, not tied to this Income (PRD #19) |

- **Postconditions:** One Income persisted.

---

## TC-11-03 — Overspend drives remaining negative *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Transport Allocation A; spend > A.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add an Expense exceeding Allocation | A + 25,000 | Transport remaining = **−25,000₫** (negative, not clamped) |

- **Postconditions:** One expense persisted.

---

## TC-11-04 — Exactly one Envelope is the Reserve *(Negative)*

- **Priority:** Medium
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Config → Envelopes; Reserve currently set.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Mark a second Envelope as Reserve | Food → Reserve | Either the previous Reserve is unset (exactly one Reserve), OR the action is blocked — never two Reserves |

- **Postconditions:** Exactly one Reserve.

---

## TC-11-05 — Editing an Allocation updates remaining live *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Food Allocation A, spent S, remaining A−S.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Change Food Allocation | A → A + 200,000 | Food remaining = **A + 200,000 − S** immediately |

- **Postconditions:** Allocation persisted.

---

## TC-11-06 — Allocation template auto-applies each month *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** An Allocation template saved.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save a template, then start a new month | template per Envelope | At month start each non-Reserve Envelope resets to its template Allocation (PRD #18,24); see flow 12 for the sweep interaction |

- **Postconditions:** Template persisted.
