import XCTest

/// Feat 4 — seeding Envelopes from the Starter set: the empty-state CTA opens the picker, select-all
/// adds the set, and an Envelope whose name already exists is shown disabled.
final class StarterEnvelopesUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testApplyStarterSetFromEmptyState() {
        let app = XCUIApplication.launchEmpty() // no seeded envelopes

        app.selectTab("Config")
        app.element(A11y.Config.envelopes).tap()
        XCTAssertTrue(app.navigationBars["Envelopes"].waitForExistence(timeout: 5))

        app.element(A11y.Starter.browse).tap()
        XCTAssertTrue(app.navigationBars["Starter envelopes"].waitForExistence(timeout: 5))
        app.buttons[A11y.Starter.selectAll].tap()
        app.buttons[A11y.Starter.add].tap()

        // The chosen starter envelopes now populate the list (assert top-of-list rows, which the
        // lazy List actually renders; later rows like "Savings" may be below the fold).
        XCTAssertTrue(app.staticTexts["Coffee"].waitForExistence(timeout: 5),
                      "Starter envelopes were not added.")
        XCTAssertTrue(app.staticTexts["Food & Dining"].exists)
    }

    func testExistingEnvelopeIsDisabledInPicker() {
        let app = XCUIApplication.launchSeeded() // seeded includes a "Transport" envelope

        app.selectTab("Config")
        app.element(A11y.Config.envelopes).tap()
        XCTAssertTrue(app.navigationBars["Envelopes"].waitForExistence(timeout: 5))

        // Open the add menu → Browse starter envelopes.
        app.navigationBars["Envelopes"].buttons["Add"].tap()
        app.buttons["Browse starter envelopes"].tap()
        XCTAssertTrue(app.navigationBars["Starter envelopes"].waitForExistence(timeout: 5))

        // "Transport" already exists → its row is disabled; a fresh one is enabled.
        XCTAssertFalse(app.element(A11y.Starter.row("Transport")).isEnabled,
                       "An already-existing envelope should be disabled in the starter picker.")
        XCTAssertTrue(app.element(A11y.Starter.row("Groceries")).isEnabled)
    }
}
