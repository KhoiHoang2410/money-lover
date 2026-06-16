import XCTest

/// Scenario 3 — manual Expense entry (PRD #10). The owner logs a coffee against the Food envelope
/// from Cash. Save must commit and dismiss back to the Calendar. Since the Add tab was replaced by
/// the Charts tab, the only add-transaction entry point is the Calendar's floating +.
final class AddExpenseUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testAddExpenseSavesAndReturns() {
        let app = XCUIApplication.launchSeeded()
        app.openNewTransaction()

        app.typeInField(A11y.Txn.amount, "45000")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")

        let save = app.buttons[A11y.Txn.save]
        XCTAssertTrue(save.isEnabled, "Save should be enabled once amount + source are set")
        save.tap()

        // Dismissed back to the Calendar.
        app.assertReturnedToCalendar("Did not return to the Calendar after saving")
    }

    /// The regression that created `docs/test-cases/`: a write in the entry form must reflect on every
    /// OTHER surface in the same session (freshness), then survive a cold start (persistence).
    /// `testAddExpenseSavesAndReturns` above stops at "form dismissed" — the gap that let the
    /// "added an expense, nothing updated" bug ship. This is the grumpy version.
    func testExpensePropagatesAcrossTabsAndSurvivesRelaunch() {
        let app = XCUIApplication.launchSeeded()

        // Baseline: net worth as currently shown (revealed).
        app.selectTab("Overview")
        let before = app.revealedNetWorth()

        // Add a 1,234₫ cash expense against Food, with a unique note to find it downstream.
        app.openNewTransaction()
        app.typeInField(A11y.Txn.amount, "1234")
        app.selectPickerOption(A11y.Txn.source, "Cash")
        app.selectPickerOption(A11y.Txn.envelope, "Food")
        app.typeInField(A11y.Txn.note, "e2e-1234")
        app.buttons[A11y.Txn.save].tap()
        app.assertReturnedToCalendar("Did not return to the Calendar after saving")

        // FRESHNESS — the silo bug. The write must reflect in OTHER tabs with no relaunch.
        app.selectTab("Overview")
        let after = app.revealedNetWorth()
        XCTAssertNotEqual(before, after,
            "Net worth unchanged after a cash expense — the Overview store went stale (the freshness bug).")

        app.selectTab("Calendar")
        let today = app.element(A11y.Calendar.day(app.todayDayNumber))
        XCTAssertTrue(today.waitForExistence(timeout: 5),
            "Today's calendar cell shows no activity after adding an expense today — the Calendar store went stale.")
        today.tap()
        XCTAssertTrue(app.staticTexts["e2e-1234"].waitForExistence(timeout: 5),
            "The expense is not listed under today in the calendar day detail.")

        // PERSISTENCE — a distinct guarantee: survive a cold start, not just an in-session reload.
        app.relaunchPreservingData()
        app.selectTab("Overview")
        let afterRelaunch = app.revealedNetWorth()
        XCTAssertEqual(after, afterRelaunch,
            "Net worth reverted after relaunch — the expense did not persist.")
    }

    func testSaveDisabledWithoutAmount() {
        let app = XCUIApplication.launchSeeded()
        app.openNewTransaction()

        let save = app.buttons[A11y.Txn.save]
        XCTAssertTrue(save.waitForExistence(timeout: 5))
        XCTAssertFalse(save.isEnabled, "Save must be disabled with no amount/source")
    }
}
