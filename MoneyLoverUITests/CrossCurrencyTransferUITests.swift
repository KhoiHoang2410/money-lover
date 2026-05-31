import XCTest

/// Scenario 4 — cross-currency Transfer (PRD #16). Move SGD from Wise to VND in VPBank; the app
/// computes the Fee from amount out, amount in, and the manual Rate.
final class CrossCurrencyTransferUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testCrossCurrencyTransferComputesFeeAndSaves() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()

        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")
        app.selectPickerOption(A11y.Txn.method, "Cross-currency")

        app.selectPickerOption(A11y.Txn.source, "Wise SGD")
        app.selectPickerOption(A11y.Txn.destination, "VPBank")

        app.typeInField(A11y.Txn.amount, "100")
        app.typeInField(A11y.Txn.amountIn, "1800000")
        app.typeInField(A11y.Txn.rate, "18500")

        // Fee row should appear (amount out × rate − amount in).
        XCTAssertTrue(app.staticTexts["Fee"].waitForExistence(timeout: 3),
                      "Fee row not shown for a cross-currency transfer")

        let save = app.element(A11y.Txn.save)
        XCTAssertTrue(save.isEnabled, "Save should be enabled for a complete cross-currency transfer")
        save.tap()

        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to Input hub after a cross-currency transfer")
    }
}
