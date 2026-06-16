import XCTest

/// Scenario 4 — cross-currency Transfer (PRD #16). Move SGD from Wise to VND in VPBank; the app
/// computes the Fee from amount out, amount in, and the manual Rate.
final class CrossCurrencyTransferUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testCrossCurrencyTransferComputesFeeAndSaves() {
        let app = XCUIApplication.launchSeeded()
        app.openNewTransaction()

        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")

        // Picking Sources of differing currencies (SGD → VND) makes the merged Transfer form reveal
        // the Amount in / Rate fields — no separate "Cross-currency" method to choose.
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

        app.assertReturnedToCalendar("Did not return to the Calendar after a cross-currency transfer")
    }

    /// Effect Contract: a cross-currency transfer carries a Fee, so net worth must DROP (the only
    /// real-money leak in an otherwise internal move), and that must survive a relaunch.
    func testCrossCurrencyTransferChangesNetWorthByFee() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()

        app.openNewTransaction()
        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")
        app.selectPickerOption(A11y.Txn.source, "Wise SGD")
        app.selectPickerOption(A11y.Txn.destination, "VPBank")
        app.typeInField(A11y.Txn.amount, "100")
        app.typeInField(A11y.Txn.amountIn, "1800000")
        app.typeInField(A11y.Txn.rate, "18500")
        app.element(A11y.Txn.save).tap()
        app.assertReturnedToCalendar()

        // The Fee is the only real-money change → net worth moved.
        let nwAfter = app.revealedNetWorth()
        XCTAssertNotEqual(nwBefore, nwAfter,
            "Net worth unchanged after a cross-currency transfer — the Fee should have reduced it.")

        // PERSISTENCE.
        app.relaunchPreservingData()
        XCTAssertEqual(nwAfter, app.revealedNetWorth(), "Net worth reverted after relaunch.")
    }
}
