import XCTest

/// "Delete all data" (Config → App). The destructive Confirm button is gated behind a 3-second
/// think-time — disabled on appear, tappable only after the cooldown — and the wipe must be total
/// and durable: it clears every surface and survives a cold relaunch.
final class DeleteAllDataUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// The Confirm button starts disabled (grayed) and becomes enabled only after the cooldown.
    func testConfirmButtonIsDisabledDuringCooldownThenEnables() {
        let app = XCUIApplication.launchSeeded()
        openDeleteSheet(app)

        let confirm = app.buttons[A11y.Config.confirmDeleteAll]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Confirm button missing on the sheet.")
        XCTAssertFalse(confirm.isEnabled, "Confirm should be disabled during the think-time cooldown.")

        XCTAssertTrue(waitUntilEnabled(confirm), "Confirm did not enable after the cooldown elapsed.")
    }

    /// Confirming wipes every seeded surface and the empty state survives a cold relaunch.
    func testDeleteAllWipesDataAndSurvivesRelaunch() {
        let app = XCUIApplication.launchSeeded()

        // Precondition: seeded data is present on Overview.
        XCTAssertTrue(app.element(A11y.Overview.sourceRow("MBBank")).waitForExistence(timeout: 5),
                      "Seeded source missing before delete — fixture not loaded.")

        openDeleteSheet(app)
        let confirm = app.buttons[A11y.Config.confirmDeleteAll]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertTrue(waitUntilEnabled(confirm), "Confirm did not enable after the cooldown elapsed.")
        confirm.tap()

        // Cross-tab effect: the wiped store shows no sources on Overview.
        app.selectTab("Overview")
        XCTAssertTrue(app.element(A11y.Overview.sourceRow("MBBank")).waitForNonExistence(timeout: 5),
                      "Source still listed after Delete all data.")

        // Durable: relaunch WITHOUT clear/seed — the empty store must persist to disk.
        app.relaunchPreservingData()
        app.selectTab("Overview")
        XCTAssertTrue(app.element(A11y.Overview.sourceRow("MBBank")).waitForNonExistence(timeout: 5),
                      "Deleted data reappeared after relaunch — wipe was not persisted.")
    }

    // MARK: - Helpers

    /// Poll an element's `isEnabled` until true or the deadline. Uses `usleep` (not `Thread.sleep`,
    /// which SIGKILLs an XCUITest run) — matching the suite's existing poll loops.
    private func waitUntilEnabled(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.isEnabled { return true }
            usleep(100_000)
        }
        return element.isEnabled
    }

    private func openDeleteSheet(_ app: XCUIApplication) {
        app.selectTab("Config")
        let row = app.element(A11y.Config.deleteAll)
        var scrolls = 0
        while !row.isHittable && scrolls < 6 {
            app.swipeUp()
            scrolls += 1
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Delete-all row missing on Config.")
        row.tap()
        XCTAssertTrue(app.staticTexts["Delete all data?"].waitForExistence(timeout: 5),
                      "Confirmation sheet did not appear.")
    }
}
