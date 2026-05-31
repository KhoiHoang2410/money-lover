import XCTest

/// Scenario 3 — manual Expense entry (PRD #10). The owner logs a coffee against the Food envelope
/// from Cash. Save must commit and return to the Input hub.
final class AddExpenseUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testAddExpenseSavesAndReturns() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")

        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))

        app.typeInField(A11y.Txn.amount, "45000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")

        let save = app.buttons[A11y.Txn.save]
        XCTAssertTrue(save.isEnabled, "Save should be enabled once amount + source are set")
        save.tap()

        // Dismissed back to the Input hub.
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after saving")
    }

    func testSaveDisabledWithoutAmount() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()

        let save = app.buttons[A11y.Txn.save]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "Save must be disabled with no amount/source")
    }
}
