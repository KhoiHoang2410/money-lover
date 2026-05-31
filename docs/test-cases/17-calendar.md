# 17 — Calendar

**Flow:** The owner views a monthly Calendar where each day shows its net (+/−); tapping a day lists its transactions; arrows and the month label navigate across months.
**Source:** PRD #51,59; ui-test-scenarios.md S11 (manual)
**Seed:** Seeded transactions across the current and prior months.

---

## TC-17-01 — Each day shows its net *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Calendar tab open on the current month.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read a day with one income and one expense | e.g. +200,000 and −45,000 | The day shows net = **+155,000₫** (sum of that day's balance-affecting txns) |
| 2 | Read a day with no transactions | — | Shows zero / blank net, not stale carryover |

- **Postconditions:** None.

---

## TC-17-02 — Tap a day lists its transactions *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** A day with known transactions.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap that day | — | A list of exactly that day's transactions appears (none from adjacent days) |

- **Postconditions:** None.

---

## TC-17-03 — Navigate months with arrows *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Calendar on month MM/YYYY.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap ‹ | — | Moves to the previous month; label updates; that month's day-nets shown |
| 2 | Tap › twice | — | Moves forward two months from current; label and grid update |

- **Postconditions:** None.

---

## TC-17-04 — Tap the label to pick any month of a year *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Calendar open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the month label | pick e.g. 03/2025 | Jumps directly to that month; grid reflects March 2025 |

- **Postconditions:** None.

---

## TC-17-05 — Day net excludes informational Backfill *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A backfilled informational transaction on a past day (see flow 08).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | View that day's net | — | The day **lists** the backfilled transaction (history complete) — confirm whether it counts toward day-net consistently with how current balance treats it; assert the spec's intended rule, not a guess |

- **Postconditions:** None.
