import XCTest

/// Flow 12 — Backfill (ADR-0012): a forgotten past entry, recorded from the Add-transaction form with
/// the **Backfilled** toggle on. It is an ordinary transaction — it shows on the calendar grid and in
/// account history — but the source's opening balance is restated so its Current balance does NOT
/// move. Balance is asserted against the Cash row (a VND account, so rate-independent and exact),
/// across a relaunch — the freshness-proof authority for a write flow (ADR-0009).
final class BackfillUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testBackfillShowsOnCalendarButKeepsBalance() {
        let app = XCUIApplication.launchSeeded()
        // The DEBUG seed commits ~100 transactions in a burst; relaunch once so every store does a
        // single clean load of the fully-committed seed before we read a baseline.
        app.relaunchPreservingData()
        let cashBefore = app.revealedSourceRow("Cash")

        // Add an expense from Cash, marked Backfilled (default date = today), unique note to find it.
        app.selectTab("Add")
        app.tapElement(A11y.Input.addTransaction)
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))
        app.typeInField(A11y.Txn.amount, "99000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")
        app.typeInField(A11y.Txn.note, "bf-99000")
        app.setToggle(A11y.Txn.backfilled, on: true)
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after saving the backfill")

        // A backfill is an ordinary transaction: it shows on the calendar grid for its date (today).
        XCTAssertTrue(app.calendarTodayContains(note: "bf-99000"),
                      "Backfill did not appear on the calendar day detail.")

        // The defining invariant, proven across a cold start: the entry persists in history and on the
        // calendar, yet Cash's Current balance is unchanged — the opening restatement absorbed it.
        app.relaunchPreservingData()
        XCTAssertTrue(app.calendarTodayContains(note: "bf-99000"),
                      "Backfill did not persist on the calendar after relaunch.")
        XCTAssertTrue(app.accountHistoryContains("Cash", note: "bf-99000"),
                      "Backfill did not appear in Cash's account history after relaunch.")
        XCTAssertEqual(cashBefore, app.revealedSourceRow("Cash"),
                       "Cash Current balance moved on a backfill — the opening restatement must absorb it.")
    }
}
