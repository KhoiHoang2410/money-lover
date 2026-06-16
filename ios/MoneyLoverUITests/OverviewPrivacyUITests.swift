import XCTest

/// Scenario 2 — Overview privacy. Amounts are censored by default (PRD #54) and the eye toggle
/// reveals them. Censored `AmountText` carries the VoiceOver label "hidden".
final class OverviewPrivacyUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testAmountsCensoredByDefault() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Overview")

        let netWorth = app.element(A11y.Overview.netWorth)
        XCTAssertTrue(netWorth.waitForExistence(timeout: 5))
        XCTAssertEqual(netWorth.label, "hidden",
                       "Net worth should be censored by default, was '\(netWorth.label)'")
    }

    func testToggleRevealsAmounts() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Overview")

        let toggle = app.element(A11y.Overview.censorToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Censor toggle missing")
        toggle.tap()

        let netWorth = app.element(A11y.Overview.netWorth)
        XCTAssertNotEqual(netWorth.label, "hidden",
                          "Net worth should be revealed after tapping the eye toggle")
        XCTAssertFalse(netWorth.label.isEmpty)
    }

    func testTapAccountOpensHistory() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Overview")

        let source = app.buttons[A11y.Overview.sourceRow("MBBank")]
        XCTAssertTrue(source.waitForExistence(timeout: 5), "MBBank source row missing")
        source.tap()
        // BUG-001 fixed: Overview now uses a single `OverviewRoute` destination and pushes reliably.
        XCTAssertTrue(app.navigationBars["MBBank"].waitForExistence(timeout: 5),
                      "Tapping the MBBank Overview row never opened Account History")
    }

    /// The Overview GOAL row navigates to goal detail (BUG-001 regression guard — see source row).
    func testTapGoalAssetOpensDetail() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Overview")
        let goal = app.buttons[A11y.Overview.goalRow("House")]
        XCTAssertTrue(goal.waitForExistence(timeout: 5), "House goal row missing on Overview")
        goal.tap()
        XCTAssertTrue(app.navigationBars["House"].waitForExistence(timeout: 5),
                      "Tapping the House goal row on Overview did not open its detail")
    }
}
