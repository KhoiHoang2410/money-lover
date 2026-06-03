import XCTest

/// Flow 15 — Income's Effect Contract. Recording income into an Account must raise that account's
/// balance and net worth, show on today's calendar, and survive a relaunch. (Income — unlike a
/// transfer — is real money arriving, so net worth MUST move.)
final class IncomeUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testIncomePropagatesAcrossTabsAndSurvivesRelaunch() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let vpBefore = app.revealedSourceRow("VPBank")

        // Income of 5,000,000₫ into VPBank, with a unique note to find downstream.
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))
        app.selectPickerOption(A11y.Txn.typePicker, "Income")
        app.selectPickerOption(A11y.Txn.source, "VPBank")
        app.typeInField(A11y.Txn.amount, "5000000")
        app.typeInField(A11y.Txn.note, "inc-5m")
        app.buttons[A11y.Txn.save].tap()
        XCTAssertTrue(app.element(A11y.Input.addTransaction).waitForExistence(timeout: 5),
                      "Did not return to the Input hub after saving income")

        // FRESHNESS — net worth and the account both rise; income shows on today's calendar.
        XCTAssertNotEqual(nwBefore, app.revealedNetWorth(),
            "Net worth did not rise after income — the Overview store went stale (the freshness bug).")
        XCTAssertNotEqual(vpBefore, app.revealedSourceRow("VPBank"),
            "VPBank balance did not rise after income (stale Overview store).")
        XCTAssertTrue(app.calendarTodayContains(note: "inc-5m"),
            "Income did not show under today in the calendar.")

        // PERSISTENCE.
        let vpAfter = app.revealedSourceRow("VPBank")
        app.relaunchPreservingData()
        XCTAssertEqual(vpAfter, app.revealedSourceRow("VPBank"), "VPBank balance reverted after relaunch.")
    }
}
