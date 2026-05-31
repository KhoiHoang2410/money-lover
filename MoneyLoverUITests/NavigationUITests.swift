import XCTest

/// Scenario 1 — the shell loads and every tab is reachable from a seeded store.
final class NavigationUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testAllTabsReachable() {
        let app = XCUIApplication.launchSeeded()

        for tab in ["Overview", "Goals", "Calendar", "Add", "Config"] {
            app.selectTab(tab)
        }

        // Back on Overview the net-worth hero must be present.
        app.selectTab("Overview")
        XCTAssertTrue(app.element(A11y.Overview.netWorth).waitForExistence(timeout: 5),
                      "Net-worth hero missing on Overview")
    }

    func testSeedDataPresent() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Goals")
        XCTAssertTrue(app.element(A11y.Goals.ring("House")).waitForExistence(timeout: 5),
                      "Seeded goal 'House' not shown")
        XCTAssertTrue(app.element(A11y.Goals.ring("Car")).exists, "Seeded goal 'Car' not shown")
        XCTAssertTrue(app.element(A11y.Goals.ring("Travel")).exists, "Seeded goal 'Travel' not shown")
    }
}
