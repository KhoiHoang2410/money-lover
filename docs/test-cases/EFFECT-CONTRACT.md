# The Effect Contract (cross-tab freshness + persistence)

A cross-cutting requirement layered over the per-flow catalog (`00`–`20`). It exists because a basic
flow shipped broken: adding a cash Expense didn't reduce Cash or show on the calendar. The math was
correct (engines are unit-tested); the break was view↔store **wiring** — each tab held a `@State`
store that loaded once and never re-read after another tab wrote. See
`docs/adr/0009-read-models-observe-modelcontext.md`.

It slipped through because the suite was **siloed**: unit tests covered the pure core, and the UI
tests asserted only *gating + "the form dismissed."* Not one test crossed a tab boundary to assert a
write was reflected elsewhere. This contract closes that class.

## Two guarantees — assert both where they apply

| Guarantee | Question | How |
|---|---|---|
| **Freshness** | After a write, does every *open-session* surface agree, with no relaunch? | Write in one tab, switch tabs, assert there. |
| **Persistence** | Does the write survive an app relaunch? | `relaunchPreservingData()` (UITEST_PRESERVE), then re-assert. |

"The form dismissed" is necessary but **never sufficient** for a write-flow.

## Mandatory effects per write-flow

Every state-changing flow asserts its change on **every surface it touches**, through shared helpers
(`UITestSupport`) so a UI change updates one helper, not many tests:

| Surface | Helper |
|---|---|
| Net worth (Overview) | `revealedNetWorth()` |
| Source row balance | `revealedSourceRow(_)` |
| Account history | `accountHistoryContains(_:note:)` |
| Calendar day cell + detail | `calendarTodayContains(note:)` / `A11y.Calendar.day(_)` |
| Relaunch survives | `relaunchPreservingData()` |

Note: the calendar grid excludes **transfers** (`CalendarMath.dailyNet`), so transfer flows assert via
source rows / history, not the day cell. **Backfills are ordinary transactions** and DO appear on the
grid (ADR-0012). Seed data can be future-dated, so `accountHistoryContains` scrolls to find a
freshly-added (now-dated) row.

## Where it's enforced (write-flows in the `00`–`20` catalog)

| Catalog flow | Contract test |
|---|---|
| `03` Add expense | `AddExpenseUITests.testExpensePropagatesAcrossTabsAndSurvivesRelaunch` |
| `05` Cross-currency transfer | `CrossCurrencyTransferUITests.testCrossCurrencyTransferChangesNetWorthByFee` |
| `06` Same-currency transfer | `TransferUITests.testSameCurrencyTransferMovesBalancesAndKeepsNetWorth` |
| `07` Reconcile | `ReconcileUITests.testReconcileAdjustsBalanceAndNetWorth` |
| `08` Backfill | `BackfillUITests.testBackfillShowsOnCalendarButKeepsBalance` |
| `09` Fund goal | `GoalContributionUITests.testContributionKeepsNetWorthAndReducesFundingAccount` |
| `11` Envelope budgeting | `EnvelopesUITests.testExpenseReducesEnvelopeRemainingAndPersists` |
| `15` Income | `IncomeUITests.testIncomePropagatesAcrossTabsAndSurvivesRelaunch` |
| `12` Month-end, `14` Voice | TODO — same contract |

Each contract test is proven to **fail** without the structural fix (negative control), not merely to
pass with it.
