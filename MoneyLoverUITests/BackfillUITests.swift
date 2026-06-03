import XCTest

/// Flow 12 — Backfill's defining grumpy expectation: an informational past entry must appear in the
/// source's history but must NOT move the Current balance or net worth (the money already left; the
/// balance is already correct). Backfills are excluded from the calendar grid, so this asserts via
/// account history + the unchanged net-worth hero.
final class BackfillUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testBackfillShowsInHistoryButDoesNotMoveBalance() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let cashBefore = app.revealedSourceRow("Cash")

        // Backfill an expense from Cash (default date = today), with a unique note to find it.
        app.selectTab("Add")
        app.element(A11y.Input.backfill).tap()
        XCTAssertTrue(app.navigationBars["Backfill"].waitForExistence(timeout: 5))
        app.typeInField(A11y.Txn.amount, "99000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")
        app.typeInField(A11y.Txn.note, "bf-99000")
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Input.backfill).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after the backfill")

        // The defining grumpy invariant: balance and net worth UNCHANGED (informational only).
        // Asserted first — these read Overview rows, before any history navigation pushes the stack.
        XCTAssertEqual(nwBefore, app.revealedNetWorth(),
                       "Net worth moved on a backfill — it must be informational only.")
        XCTAssertEqual(cashBefore, app.revealedSourceRow("Cash"),
                       "Cash balance moved on a backfill — it must not affect the Current balance.")
        // …yet it still shows in Cash's history (this leaves history pushed — done last).
        XCTAssertTrue(app.accountHistoryContains("Cash", note: "bf-99000"),
                      "Backfill did not appear in Cash's account history.")

        // PERSISTENCE — still informational, still no balance impact, after a cold start.
        app.relaunchPreservingData()
        XCTAssertEqual(cashBefore, app.revealedSourceRow("Cash"),
                       "Cash balance changed after relaunch — the backfill leaked into the balance.")
        XCTAssertTrue(app.accountHistoryContains("Cash", note: "bf-99000"),
                      "Backfill did not persist in history after relaunch.")
    }
}
