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

## TC-17-05 — Day net includes Backfill *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** `CalendarMathTests.includesBackfilledEntries`
- **Preconditions:** A backfilled transaction on a past day (see flow 08). A Backfill is an ordinary transaction (ADR-0012).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | View that day's net | — | The day **lists** the backfilled transaction **and** counts it toward the day-net, exactly like any other expense/income — it is an ordinary transaction. (Its source's Current balance is unchanged because the Opening balance was restated when it was recorded.) |

- **Postconditions:** None.

---

## TC-17-06 — Floating + adds a transaction on the picked day *(Happy path — feat 1)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `CalendarEditDeleteUITests.testFloatingButtonAddsTransactionOnToday`
- **Preconditions:** Calendar tab open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the floating + | — | The full add-transaction form opens (Expense/Income/Transfer/Invest) |
| 2 | The date is prefilled | selected day, else today | Matches the day being viewed; editable in the form |
| 3 | Save an expense | VPBank, 123,000 | It appears under that day's detail and in the account history |

- **Postconditions:** One transaction added on the chosen date.

---

## TC-17-07 — Tap a day-detail row to edit *(Positive — feat 5)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `CalendarEditDeleteUITests.testEditFromCalendarChangesTheAmount`
- **Preconditions:** A day with at least one non-Adjustment transaction.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap a transaction row | — | The merged form opens in **Edit** mode, all fields prefilled |
| 2 | Change the amount, Save | 100,000 → 900,000 | The row updates in place (same id); balances recompute |
| 3 | View an Adjustment row | — | Not tappable here (Adjustments are Reconcile-owned, not edited/deleted from the calendar) |

- **Postconditions:** The edited transaction is updated, not duplicated.

---

## TC-17-08 — Delete from the row's form *(Positive — feat 5)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `CalendarEditDeleteUITests.testDeleteFromCalendarRemovesRow`
- **Preconditions:** A day with a deletable transaction.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the row to open it | — | The edit form opens |
| 2 | Tap **Delete transaction** | confirm setting **off** (default) | Removed immediately; form dismisses; balances/quantities recompute |

- **Postconditions:** Transaction gone from history and totals.

---

## TC-17-09 — Opt-in confirmation before delete *(Edge — setting)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** `CalendarEditDeleteUITests.testConfirmBeforeDeleteShowsDialogWhenEnabled`
- **Preconditions:** Config → Appearance → "Ask before deleting" turned **on**.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open a row and tap Delete transaction | setting **on** | A confirmation alert appears first |
| 2 | Confirm Delete | — | The row is removed |

- **Postconditions:** Setting persists; default is off.
