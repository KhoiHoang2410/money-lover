import XCTest

/// Feat 3 / ADR-0010 — the dedicated Holdings screen adds a gold holding by quantity only (no money
/// field), it appears in the list, and it survives a cold start.
final class AddHoldingUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testAddGoldHoldingByQuantityPersists() {
        let app = XCUIApplication.launchSeeded()

        openHoldings(app)
        app.element(A11y.Holding.add).tap()
        XCTAssertTrue(app.navigationBars["Add holding"].waitForExistence(timeout: 5))
        // Asset type defaults to Gold; enter quantity only — there is no VND/opening-balance field.
        app.typeInField(A11y.Holding.quantity, "2")
        app.buttons[A11y.Holding.save].tap()

        XCTAssertTrue(app.staticTexts["Gold"].waitForExistence(timeout: 5),
                      "New gold holding did not appear on the Holdings screen.")

        // PERSISTENCE — survives relaunch.
        app.relaunchPreservingData()
        openHoldings(app)
        XCTAssertTrue(app.staticTexts["Gold"].waitForExistence(timeout: 5),
                      "Gold holding did not survive a cold start.")
    }

    private func openHoldings(_ app: XCUIApplication) {
        app.selectTab("Config")
        app.element(A11y.Config.holdings).tap()
        XCTAssertTrue(app.navigationBars["Holdings"].waitForExistence(timeout: 5))
    }
}
