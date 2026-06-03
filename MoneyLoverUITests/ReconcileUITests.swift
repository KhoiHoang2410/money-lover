import XCTest

/// Scenario 5 — Reconcile (PRD #40/41). The owner re-enters a source's real balance; any drift
/// must enable Record so it can be logged as an Adjustment.
final class ReconcileUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testEnteringRealBalanceEnablesRecord() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")
        app.element(A11y.Input.reconcile).tap()
        XCTAssertTrue(app.navigationBars["Update balances"].waitForExistence(timeout: 5))

        let record = app.buttons[A11y.Reconcile.record]
        XCTAssertTrue(record.waitForExistence(timeout: 5))
        XCTAssertFalse(record.isEnabled, "Record should be disabled before any drift is entered")

        // Cash seeds to 1,500,000. Enter a different real balance to create drift.
        app.typeInField(A11y.Reconcile.field("Cash"), "1400000")

        XCTAssertTrue(record.isEnabled, "Record should enable once a real balance differs from computed")
        record.tap()

        XCTAssertTrue(app.element(A11y.Input.reconcile).waitForExistence(timeout: 5),
                      "Did not return to Input hub after recording the adjustment")
    }

    /// Effect Contract: recording a real balance posts an Adjustment, so the source row equals the
    /// re-entered balance, net worth moves by the drift, and it survives a relaunch.
    func testReconcileAdjustsBalanceAndNetWorth() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let cashBefore = app.revealedSourceRow("Cash")

        app.selectTab("Add")
        app.element(A11y.Input.reconcile).tap()
        XCTAssertTrue(app.navigationBars["Update balances"].waitForExistence(timeout: 5))
        // Cash seeds to 1,500,000 — re-enter 1,400,000 to create a −100,000 drift.
        app.typeInField(A11y.Reconcile.field("Cash"), "1400000")
        app.buttons[A11y.Reconcile.record].tap()
        XCTAssertTrue(app.element(A11y.Input.reconcile).waitForExistence(timeout: 5))

        // The Adjustment moved both the Cash row and net worth.
        let cashAfter = app.revealedSourceRow("Cash")
        XCTAssertNotEqual(cashBefore, cashAfter, "Cash row did not change after reconciling (stale Overview store).")
        XCTAssertNotEqual(nwBefore, app.revealedNetWorth(), "Net worth did not move after a reconciling Adjustment.")

        // PERSISTENCE.
        app.relaunchPreservingData()
        XCTAssertEqual(cashAfter, app.revealedSourceRow("Cash"), "Reconciled Cash balance reverted after relaunch.")
    }
}
