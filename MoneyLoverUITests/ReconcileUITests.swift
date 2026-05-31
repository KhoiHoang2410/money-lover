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
}
