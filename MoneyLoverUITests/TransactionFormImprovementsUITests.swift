import XCTest

/// Covers the transaction-form quality-of-life features:
/// - feat 2: the From/Envelope pickers remember the last-committed choice and prefill the next
///   new transaction, so a repeat entry needs only an amount.
/// - feat 3: an **OK** accessory button above the keyboard accepts the value and dismisses it.
final class TransactionFormImprovementsUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// After saving an expense from Cash, reopening the form prefills Cash — so typing an amount
    /// alone (no source pick) is enough to enable Save. A fresh seed starts with no remembered
    /// default, so Save stays disabled until the first save establishes it.
    func testRemembersSourceForNextTransaction() {
        let app = XCUIApplication.launchSeeded()

        // First entry — pick Cash explicitly and save.
        app.openNewTransaction()
        app.typeInField(A11y.Txn.amount, "45000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.buttons[A11y.Txn.save].tap()
        app.assertReturnedToCalendar("Did not return to the Calendar after saving")

        // Second entry — amount only, no source pick. Save should already be enabled because the
        // remembered Cash default was applied.
        app.openNewTransaction()
        app.typeInField(A11y.Txn.amount, "12000")
        let save = app.buttons[A11y.Txn.save]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertTrue(save.isEnabled,
                      "Save should be enabled from the remembered source — the From default was not reused.")
    }

    /// The keyboard's OK accessory appears for the auto-focused amount field and dismisses the
    /// keyboard when tapped.
    func testKeyboardOKDismissesTheKeyboard() {
        let app = XCUIApplication.launchSeeded()
        app.openNewTransaction()

        let ok = app.buttons[A11y.Txn.keyboardDone]
        XCTAssertTrue(ok.waitForExistence(timeout: 5),
                      "The OK keyboard accessory did not appear for the focused amount field.")
        ok.tap()
        XCTAssertFalse(ok.waitForExistence(timeout: 2),
                       "The keyboard (and its OK button) should be gone after tapping OK.")
    }
}
