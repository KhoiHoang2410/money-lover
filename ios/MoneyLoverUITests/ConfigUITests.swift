import XCTest

/// Scenario 20 — Configuration management (ISSUE #33 criterion 6).
///
/// Every Config setup area must be reachable from the Config tab, and the Config list must stay
/// usable across device rotation (TC-20-04). Rows that carry a stable `A11y.Config` identifier are
/// tapped by identifier; the two Insights rows (Charts, Advice) ship without identifiers in
/// `ConfigScreen.swift`, so they are driven by their visible label and asserted via the destination
/// navigation-bar title verified in the screen sources.
final class ConfigUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    // MARK: - Each Config area is reachable

    /// Config → "Sources & balances" pushes `SourcesScreen` (nav title "Sources").
    func testSourcesAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.element(A11y.Config.sources)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Sources row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Sources"].waitForExistence(timeout: 5),
                      "Tapping Sources did not open the Sources screen")
    }

    /// Config → "Envelopes & template" pushes `EnvelopesScreen` (nav title "Envelopes").
    func testEnvelopesAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.element(A11y.Config.envelopes)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Envelopes row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Envelopes"].waitForExistence(timeout: 5),
                      "Tapping Envelopes did not open the Envelopes screen")
    }

    /// Config → "Rates & prices" pushes `RatesScreen` (nav title "Rates & prices").
    func testRatesAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.element(A11y.Config.rates)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Rates row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Rates & prices"].waitForExistence(timeout: 5),
                      "Tapping Rates did not open the Rates & prices screen")
    }

    /// Config → "Run month-end sweep" pushes `MonthEndScreen` (nav title "Month-end sweep").
    func testMonthEndAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.element(A11y.Config.monthEnd)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Month-end row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Month-end sweep"].waitForExistence(timeout: 5),
                      "Tapping Month-end did not open the Month-end sweep screen")
    }

    /// Config → "Appearance" pushes `AppearanceScreen` (nav title "Appearance").
    /// The Appearance row in `ConfigScreen.swift` ships without an `A11y` identifier (unlike the Money
    /// rows), so it is located by its visible label and sits in the lower "App" section, requiring a
    /// scroll into view before tapping.
    func testAppearanceAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.buttons["Appearance"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Appearance row missing on Config")
        var scrolls = 0
        while !row.isHittable && scrolls < 5 {
            app.swipeUp()
            scrolls += 1
        }
        row.tap()
        XCTAssertTrue(app.navigationBars["Appearance"].waitForExistence(timeout: 5),
                      "Tapping Appearance did not open the Appearance screen")
    }

    /// Config → "Charts & trends" pushes `ChartsScreen` (nav title "Charts").
    /// The Insights row carries no `A11y` identifier in `ConfigScreen.swift`, so it is located by its
    /// visible label and verified via the destination nav-bar title from `ChartsScreen.swift`.
    func testChartsAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.buttons["Charts & trends"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Charts row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Charts"].waitForExistence(timeout: 5),
                      "Tapping Charts did not open the Charts screen")
    }

    /// Config → "Advice" pushes `AdviceScreen` (nav title "Advice").
    /// The Insights row carries no `A11y` identifier in `ConfigScreen.swift`, so it is located by its
    /// visible label and verified via the destination nav-bar title from `AdviceScreen.swift`.
    func testAdviceAreaReachable() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.buttons["Advice"]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Advice row missing on Config")
        row.tap()
        XCTAssertTrue(app.navigationBars["Advice"].waitForExistence(timeout: 5),
                      "Tapping Advice did not open the Advice screen")
    }

    // MARK: - Layout: portrait ↔ landscape (TC-20-04)

    /// Rotating the device must not strand the Config list: a known row stays present and hittable in
    /// both portrait and landscape, then the orientation is restored for the next test.
    func testConfigSurvivesRotation() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")

        let row = app.element(A11y.Config.sources)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Sources row missing in portrait")
        XCTAssertTrue(row.isHittable, "Sources row not hittable in portrait")

        XCUIDevice.shared.orientation = .landscapeRight
        defer { XCUIDevice.shared.orientation = .portrait }

        let landscapeRow = app.element(A11y.Config.sources)
        XCTAssertTrue(landscapeRow.waitForExistence(timeout: 5),
                      "Sources row vanished after rotating to landscape (clipping/overlap?)")
        XCTAssertTrue(landscapeRow.isHittable,
                      "Sources row not hittable in landscape — content may be clipped")

        XCUIDevice.shared.orientation = .portrait

        let backRow = app.element(A11y.Config.sources)
        XCTAssertTrue(backRow.waitForExistence(timeout: 5),
                      "Sources row missing after rotating back to portrait")
        XCTAssertTrue(backRow.isHittable, "Sources row not hittable after rotating back to portrait")
    }
}
