import XCTest

/// Feat 6 / ADR-0010 — an Invest Buy moves money out of the funding VND Account (Effect Contract:
/// freshness + persistence), and the Sell guard blocks selling more units than are held.
final class InvestTradeUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testBuyDebitsAccountAndPersists() {
        let app = XCUIApplication.launchSeeded()

        let vpBefore = app.revealedSourceRow("VPBank")

        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))
        app.selectPickerOption(A11y.Txn.typePicker, "Invest")
        app.selectPickerOption(A11y.Txn.tradeDirection, "Buy")
        app.selectPickerOption(A11y.Txn.source, "VPBank")
        app.selectPickerOption(A11y.Txn.holding, "Gold SJC")
        app.typeInField(A11y.Txn.quantity, "2")
        app.typeInField(A11y.Txn.unitPrice, "7000000")
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after the Buy")

        // FRESHNESS — the funding account dropped (₫14,000,000 spent on gold).
        let vpAfter = app.revealedSourceRow("VPBank")
        XCTAssertNotEqual(vpBefore, vpAfter, "VPBank did not drop after buying gold (stale Overview store).")

        // PERSISTENCE — the debit survives a cold start.
        app.relaunchPreservingData()
        XCTAssertEqual(vpAfter, app.revealedSourceRow("VPBank"), "VPBank balance reverted after relaunch.")
    }

    func testSellOverHoldingsDisablesSave() {
        // Gold SJC is seeded with 5 chỉ; selling 9 is impossible → Save disabled.
        let app = openSellForm(quantity: "9")
        XCTAssertFalse(app.buttons[A11y.Txn.save].isEnabled, "Save was enabled for an oversell (9 of 5 chỉ).")
    }

    func testSellWithinHoldingsEnablesSave() {
        // Selling 3 of 5 chỉ is valid → Save enabled (proves the other fields are sufficient).
        let app = openSellForm(quantity: "3")
        XCTAssertTrue(app.buttons[A11y.Txn.save].isEnabled, "Save stayed disabled for a valid sell (3 of 5 chỉ).")
    }

    /// Opens the Invest form set to Sell Gold SJC from VPBank at ₫8,000,000, with `quantity` entered
    /// once (no re-typing — a single type is the reliable path through `typeInField`).
    private func openSellForm(quantity: String) -> XCUIApplication {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))
        app.selectPickerOption(A11y.Txn.typePicker, "Invest")
        app.selectPickerOption(A11y.Txn.tradeDirection, "Sell")
        app.selectPickerOption(A11y.Txn.source, "VPBank")
        app.selectPickerOption(A11y.Txn.holding, "Gold SJC")
        app.typeInField(A11y.Txn.unitPrice, "8000000")
        app.typeInField(A11y.Txn.quantity, quantity)
        return app
    }
}
