import XCTest

/// Flow 11 — Envelope budgeting, the freshness slice: an Expense assigned to an Envelope must
/// reduce that Envelope's remaining, reflected on Config → Envelopes without a relaunch, and the
/// reduction must persist. (The remaining = Allocation − Σ spent; a stale store would not update.)
final class EnvelopesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testExpenseReducesEnvelopeRemainingAndPersists() {
        let app = XCUIApplication.launchSeeded()

        let foodBefore = app.envelopeRemaining("Food")

        // Spend 50,000₫ against Food from Cash.
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))
        app.typeInField(A11y.Txn.amount, "50000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after saving")

        // FRESHNESS — Food's remaining dropped, reflected on the Envelopes screen with no relaunch.
        let foodAfter = app.envelopeRemaining("Food")
        XCTAssertNotEqual(foodBefore, foodAfter,
            "Food's remaining did not change after an expense assigned to it — the Envelopes store went stale.")

        // PERSISTENCE.
        app.relaunchPreservingData()
        XCTAssertEqual(foodAfter, app.envelopeRemaining("Food"),
            "Food's remaining reverted after relaunch — the expense did not persist.")
    }
}
