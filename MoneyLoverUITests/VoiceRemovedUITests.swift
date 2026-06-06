import XCTest

/// Feat 2 — the voice-expense entry is removed. The Input hub still offers the other entry modes
/// but no longer shows a Voice option.
final class VoiceRemovedUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testInputHubHasNoVoiceEntry() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")

        // The hub is up (other modes still present)…
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(A11y.Input.reconcile).exists)
        XCTAssertTrue(app.element(A11y.Input.backfill).exists)

        // …but Voice expense is gone.
        XCTAssertFalse(app.staticTexts["Voice expense"].exists, "Voice expense entry is still present.")
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "input.voice").firstMatch.exists,
                       "The voice route identifier is still present.")
    }
}
