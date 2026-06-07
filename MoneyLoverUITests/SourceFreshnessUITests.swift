import XCTest

/// Regression for the empty source-picker bug: a `Source` created after the Calendar tab's input
/// store had already loaded must appear in the transaction form's "From" picker without relaunching
/// the app. The store used to build once and never reload, so the picker stayed empty even though the
/// account existed (e.g. a Cash account created in onboarding/Config showed a balance elsewhere but
/// couldn't be selected for an expense). The add-transaction form now opens from the Calendar's
/// floating + (the Add tab was replaced by the Charts tab), so the Calendar owns that input store.
final class SourceFreshnessUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSourceCreatedAfterInputLoadedAppearsInPicker() {
        let app = XCUIApplication.launchEmpty()

        // 1. Visit Calendar first so its input store builds and loads against an EMPTY store — the
        //    exact precondition of the bug (the picker had nothing because nothing existed at load).
        app.selectTab("Calendar")
        XCTAssertTrue(app.element(A11y.Calendar.addTransaction).waitForExistence(timeout: 5),
                      "Calendar did not appear")

        // 2. Create sources in another tab, after the Calendar's input store already loaded. Use the
        //    waiting tap: a raw `element(_:).tap()` right after a tab switch races the Config list's
        //    first render and fails as "No matches found for config.seedSample" (see `tapElement`).
        app.selectTab("Config")
        app.tapElement(A11y.Config.seedSample)

        // 3. Back on the Calendar +, the freshly-created sources must be selectable in the picker.
        app.openNewTransaction()
        app.typeInField(A11y.Txn.amount, "45000")
        app.selectPickerOption(A11y.Txn.source, "Cash")

        XCTAssertTrue(app.buttons[A11y.Txn.save].isEnabled,
                      "A source created after the Calendar's input store first loaded must be selectable; an empty picker means the store went stale.")
    }
}
