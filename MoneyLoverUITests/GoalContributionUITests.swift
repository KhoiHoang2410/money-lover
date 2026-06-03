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
}
