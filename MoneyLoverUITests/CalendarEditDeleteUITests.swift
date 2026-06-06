import XCTest

/// Feat 1 & 5 — the Calendar floating + adds a transaction on the viewed day, and day-detail rows
/// can be edited and deleted (with an opt-in confirmation).
final class CalendarEditDeleteUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testFloatingButtonAddsTransactionOnToday() {
        let app = XCUIApplication.launchSeeded()
        addExpenseViaFAB(app, note: "FAB lunch", amount: "123000")

        openToday(app)
        XCTAssertTrue(app.element(A11y.Calendar.txn("FAB lunch")).waitForExistence(timeout: 5),
                      "Transaction added via the floating + did not appear on today.")
    }

    func testEditFromCalendarChangesTheAmount() {
        let app = XCUIApplication.launchSeeded()
        addExpenseViaFAB(app, note: "Edit me", amount: "100000")

        let vpAfterAdd = app.revealedSourceRow("VPBank")

        openToday(app)
        app.element(A11y.Calendar.txn("Edit me")).tap()
        XCTAssertTrue(app.navigationBars["Edit transaction"].waitForExistence(timeout: 5),
                      "Tapping a day-detail row did not open the edit form.")
        app.typeInField(A11y.Txn.amount, "900000")
        app.buttons[A11y.Txn.save].tap()

        let vpAfterEdit = app.revealedSourceRow("VPBank")
        XCTAssertNotEqual(vpAfterAdd, vpAfterEdit, "Editing the amount did not change the account balance.")
    }

    func testDeleteFromCalendarRemovesRow() {
        let app = XCUIApplication.launchSeeded()
        addExpenseViaFAB(app, note: "Delete me", amount: "77000")

        openToday(app)
        // Tap the row to open it, then delete from the form (confirm setting is off by default).
        app.element(A11y.Calendar.txn("Delete me")).tap()
        XCTAssertTrue(app.navigationBars["Edit transaction"].waitForExistence(timeout: 5))
        app.buttons[A11y.Txn.delete].tap()

        XCTAssertTrue(app.element(A11y.Calendar.txn("Delete me")).waitForNonExistence(timeout: 5),
                      "Deleted transaction is still listed.")
    }

    func testConfirmBeforeDeleteShowsDialogWhenEnabled() {
        let app = XCUIApplication.launchSeeded()
        // Turn on the opt-in confirmation in Appearance.
        app.selectTab("Config")
        app.element(A11y.Config.appearance).tap()
        let toggle = app.switches[A11y.Config.confirmDelete]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        // A SwiftUI Form Toggle ignores a center tap; hit the switch control on the trailing edge.
        if toggle.value as? String != "1" {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(toggle.value as? String, "1", "Confirm-delete toggle did not turn on.")

        addExpenseViaFAB(app, note: "Confirm me", amount: "55000")
        openToday(app)
        app.element(A11y.Calendar.txn("Confirm me")).tap()
        XCTAssertTrue(app.navigationBars["Edit transaction"].waitForExistence(timeout: 5))

        // With the setting on, the form's Delete asks for confirmation instead of deleting.
        app.buttons[A11y.Txn.delete].tap()
        let alert = app.alerts["Delete this transaction?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No confirmation alert appeared with delete enabled.")
        alert.buttons["Delete"].tap()
        XCTAssertTrue(app.element(A11y.Calendar.txn("Confirm me")).waitForNonExistence(timeout: 5),
                      "Confirmed delete did not remove the row.")
    }

    // MARK: - Helpers

    private func addExpenseViaFAB(_ app: XCUIApplication, note: String, amount: String) {
        app.selectTab("Calendar")
        app.element(A11y.Calendar.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5),
                      "Floating + did not open the add form.")
        app.selectPickerOption(A11y.Txn.source, "VPBank")
        app.typeInField(A11y.Txn.amount, amount)
        app.typeInField(A11y.Txn.note, note)
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Calendar.addTransaction).waitForExistence(timeout: 5),
                      "Add form did not dismiss back to the Calendar.")
    }

    private func openToday(_ app: XCUIApplication) {
        app.selectTab("Calendar")
        let today = app.element(A11y.Calendar.day(app.todayDayNumber))
        XCTAssertTrue(today.waitForExistence(timeout: 5))
        today.tap()
    }
}
