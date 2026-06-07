import XCTest

/// Scenario 6 — fund a Goal (PRD #27, ADR-0007). Open a goal, add money from a VND account,
/// and confirm the contribution sheet drives the flow.
final class GoalContributionUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testContributeToGoal() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Goals")

        let ring = app.element(A11y.Goals.ring("Travel"))
        XCTAssertTrue(ring.waitForExistence(timeout: 5), "Travel goal ring missing")
        ring.tap()

        let contribute = app.element(A11y.Goals.detailContribute)
        XCTAssertTrue(contribute.waitForExistence(timeout: 5), "Add-money button missing on goal detail")
        contribute.tap()

        app.typeInField(A11y.Goals.contributionAmount, "2000000")
        app.selectPickerOption(A11y.Goals.contributionAccount, "MBBank")

        let save = app.element(A11y.Goals.contributionSave)
        XCTAssertTrue(save.isEnabled, "Save should be enabled with amount + account")
        save.tap()

        // Sheet dismissed; back on the goal detail (its title is the goal name).
        XCTAssertTrue(app.navigationBars["Travel"].waitForExistence(timeout: 5),
                      "Contribution sheet did not dismiss back to the goal detail")
    }

    /// Effect Contract: a contribution is a Transfer (Account → Goal), so the funding Account drops
    /// and **net worth is unchanged** — one Asset becomes another (ADR-0007). And it survives relaunch.
    func testContributionKeepsNetWorthAndReducesFundingAccount() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let mbBefore = app.revealedSourceRow("MBBank")

        app.selectTab("Goals")
        app.element(A11y.Goals.ring("Travel")).tap()
        app.element(A11y.Goals.detailContribute).tap()
        app.typeInField(A11y.Goals.contributionAmount, "2000000")
        app.selectPickerOption(A11y.Goals.contributionAccount, "MBBank")
        app.element(A11y.Goals.contributionSave).tap()
        XCTAssertTrue(app.navigationBars["Travel"].waitForExistence(timeout: 5))

        // Net worth UNCHANGED (asset→asset); the funding account dropped.
        XCTAssertEqual(nwBefore, app.revealedNetWorth(),
            "Net worth changed on a goal contribution — funding a Goal moves one Asset into another (ADR-0007).")
        let mbAfter = app.revealedSourceRow("MBBank")
        XCTAssertNotEqual(mbBefore, mbAfter, "MBBank did not drop after funding the goal (stale Overview store).")

        // PERSISTENCE.
        app.relaunchPreservingData()
        XCTAssertEqual(nwBefore, app.revealedNetWorth(), "Net worth diverged after relaunch.")
        XCTAssertEqual(mbAfter, app.revealedSourceRow("MBBank"), "Funding account reverted after relaunch.")
    }

    /// Funding a Goal from the add-transaction form (Transfer → Goal) is the same Account → Goal
    /// transfer as the goal detail's "Add money": net worth is unchanged (Asset → Asset) and the
    /// funding Account drops. And it survives relaunch (ADR-0007).
    func testFundGoalViaTransferKeepsNetWorthAndReducesAccount() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let mbBefore = app.revealedSourceRow("MBBank")

        app.openNewTransaction()
        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")
        app.selectPickerOption(A11y.Txn.method, "Goal")
        app.selectPickerOption(A11y.Txn.source, "MBBank")
        app.selectPickerOption(A11y.Txn.destination, "Travel")
        app.typeInField(A11y.Txn.amount, "2000000")
        app.buttons[A11y.Txn.save].tap()
        app.assertReturnedToCalendar("Did not return to the Calendar after funding the goal")

        // Net worth UNCHANGED (asset→asset); the funding account dropped.
        XCTAssertEqual(nwBefore, app.revealedNetWorth(),
            "Net worth changed funding a goal via Transfer — money moves one Asset into another (ADR-0007).")
        let mbAfter = app.revealedSourceRow("MBBank")
        XCTAssertNotEqual(mbBefore, mbAfter, "MBBank did not drop after funding the goal via Transfer.")

        // PERSISTENCE.
        app.relaunchPreservingData()
        XCTAssertEqual(nwBefore, app.revealedNetWorth(), "Net worth diverged after relaunch.")
        XCTAssertEqual(mbAfter, app.revealedSourceRow("MBBank"), "Funding account reverted after relaunch.")
    }

    /// A goal contribution opens read-only — it can't be edited or undone (ADR-0007). Tapping one in
    /// the Calendar day detail shows the "Goal contribution" summary with no Save action, instead of
    /// the editable transfer form (which would otherwise drop the goal link on save).
    func testGoalContributionOpensReadOnly() {
        let app = XCUIApplication.launchSeeded()

        // Create a contribution dated today (Transfer → Goal defaults to today), then open it from
        // the Calendar day detail by its note.
        app.openNewTransaction()
        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")
        app.selectPickerOption(A11y.Txn.method, "Goal")
        app.selectPickerOption(A11y.Txn.source, "MBBank")
        app.selectPickerOption(A11y.Txn.destination, "Travel")
        app.typeInField(A11y.Txn.amount, "1500000")
        app.buttons[A11y.Txn.save].tap()
        app.assertReturnedToCalendar()

        XCTAssertTrue(app.calendarTodayContains(note: "→ Travel"),
                      "The goal contribution is not listed under today in the Calendar.")
        app.staticTexts["→ Travel"].tap()

        XCTAssertTrue(app.navigationBars["Goal contribution"].waitForExistence(timeout: 5),
                      "Tapping a goal contribution did not open the read-only summary.")
        XCTAssertFalse(app.element(A11y.Txn.save).waitForExistence(timeout: 2),
                       "A goal contribution must not offer Save — it can't be edited here.")
        XCTAssertFalse(app.element(A11y.Txn.delete).exists,
                       "A goal contribution must not offer Delete — there's no undo here.")
    }
}
