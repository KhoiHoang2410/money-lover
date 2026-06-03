# 08 — Backfill a forgotten past transaction

**Flow:** The owner logs a forgotten past transaction flagged informational; history is completed without disturbing the current (already-correct) balance.
**Source:** PRD #42; ADR-0006 (BalanceEngine ignores Backfill); CONTEXT.md (affectsBalance flag)
**Seed:** Cash and MBBank Accounts with current balances.

---

## TC-08-01 — Backfill adds history without changing current balance *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** BackfillUITests.testBackfillShowsInHistoryButDoesNotMoveBalance — shows in history, balance + net worth UNCHANGED, survives relaunch (EFFECT-CONTRACT.md)
- **Preconditions:** Note Cash current balance C; net worth N.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Backfill mode | — | Backfill entry shown, marked informational |
| 2 | Enter a past expense | date = last month, amount 60,000, source Cash, Envelope Food | Form accepts a past date |
| 3 | Save | — | Transaction appears in Cash history with the past date AND an informational flag |
| 4 | Read Cash current balance | — | **C unchanged** (Backfill does not affect current balance) |
| 5 | Read net worth | — | **N unchanged** |

- **Postconditions:** One informational transaction persisted.

---

## TC-08-02 — Backfill is excluded from current-balance math *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Cash current C.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Backfill several past transactions | varied amounts/dates | Cash current balance still = C after all of them (sum excludes informational txns) |

- **Postconditions:** Informational transactions persisted.

---

## TC-08-03 — Backfill appears on the correct historical date *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Backfill a transaction dated to a past month.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Calendar, navigate to the backfilled month | — | The day shows the transaction; it contributes to that day's net and historical charts, but not to current balance |

- **Postconditions:** None.

---

## TC-08-04 — Backfill does not affect Envelope remaining for the current month *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Note current-month Food remaining R.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Backfill a past-month Food expense | last-month date, 60,000 | Current-month Food remaining still = R (informational past spend doesn't reopen a closed month's budget) |

- **Postconditions:** Informational transaction persisted.
