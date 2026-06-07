# 08 — Backfill a forgotten past transaction

**Flow:** The owner logs a forgotten past transaction via the **Backfilled** toggle on the add-transaction form. It is recorded as an ordinary transaction (it shows on the calendar and in history), and the source's **Opening balance** is restated by the offsetting amount so the Current balance is unchanged.
**Source:** PRD #42; ADR-0012 (Backfill = normal transaction + opening restatement); CONTEXT.md (Backfill).
**Seed:** Cash and MBBank Accounts with current balances.

---

## TC-08-01 — Backfill shows on the calendar but keeps the current balance *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** BackfillUITests.testBackfillShowsOnCalendarButKeepsBalance — shows on calendar + history, Cash balance UNCHANGED, survives relaunch (EFFECT-CONTRACT.md)
- **Preconditions:** Note Cash current balance C.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open the add-transaction form (calendar `+`), pick Expense | — | The form shows a **Backfilled** toggle |
| 2 | Enter a past expense and turn on **Backfilled** | date = today/past, amount 99,000, source Cash, Envelope Food | Form accepts it |
| 3 | Save | — | The transaction appears on the calendar day and in Cash history, with no special marker (it's an ordinary transaction) |
| 4 | Read Cash current balance | — | **C unchanged** (the Opening balance was restated to absorb it) |

- **Postconditions:** One transaction persisted; Cash Opening balance raised by the amount.

---

## TC-08-02 — Current balance stays put via the opening restatement *(Positive — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** InputStoreBackfillTests.backfillExpenseRestatesOpeningAndKeepsCurrentBalance / backfillIncomeRestatesOpeningAndKeepsCurrentBalance
- **Preconditions:** A source with a known current balance C and opening O.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Backfill an expense of A | amount A | Opening becomes O + A; current balance still = C; the entry is counted by `CalendarMath.dailyNet` on its day |
| 2 | Backfill an income of B | amount B | Opening becomes O − B; current balance still = C |

- **Postconditions:** Transactions persisted; current balance unchanged.

---

## TC-08-03 — Backfill appears on the correct historical date *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** CalendarMathTests.includesBackfilledEntries (engine); BackfillUITests (e2e, today)
- **Preconditions:** Backfill a transaction dated to a past day.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Calendar, navigate to the backfilled day | — | The day lists the transaction and **counts it toward that day's net** and historical charts, like any other entry. The source's current balance is unchanged (opening restated). |

- **Postconditions:** None.

---

## TC-08-04 — A backfilled envelope expense reduces that envelope's remaining *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Note Food remaining R. (A Backfill is an ordinary expense — ADR-0012 — so it counts toward its envelope; this supersedes the old "informational, excluded" rule.)

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Backfill a Food expense | amount 60,000, Envelope Food | Food remaining becomes R − 60,000 — a backfilled expense counts like any other expense in that envelope |

- **Postconditions:** Transaction persisted.
