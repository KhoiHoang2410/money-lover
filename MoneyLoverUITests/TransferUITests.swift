import XCTest

/// Flow 03 (same-currency) — the Effect Contract. A VPBank→Cash transfer must move both balances
/// while leaving net worth exactly unchanged (money goes Account→Account), and persist a relaunch.
/// Transfers are excluded from the calendar grid (`CalendarMath.dailyNet`), so this asserts via the
/// source rows and the net-worth hero, not the day cell.
final class TransferUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testSameCurrencyTransferMovesBalancesAndKeepsNetWorth() {
        let app = XCUIApplication.launchSeeded()

        let nwBefore = app.revealedNetWorth()
        let vpBefore = app.revealedSourceRow("VPBank")
        let cashBefore = app.revealedSourceRow("Cash")

        // VPBank → Cash, same currency (both VND) — the merged Transfer mode shows a single Amount
        // when the two Sources share a currency (no Amount in / Rate).
        app.openNewTransaction()
        app.selectPickerOption(A11y.Txn.typePicker, "Transfer")
        app.selectPickerOption(A11y.Txn.source, "VPBank")
        app.selectPickerOption(A11y.Txn.destination, "Cash")
        app.typeInField(A11y.Txn.amount, "500000")
        app.buttons[A11y.Txn.save].tap()
        app.assertReturnedToCalendar("Did not return to the Calendar after the transfer")

        // FRESHNESS — both rows moved, net worth unchanged (Account→Account).
        let nwAfter = app.revealedNetWorth()
        XCTAssertEqual(nwBefore, nwAfter,
            "A same-currency transfer changed net worth — money moved between accounts, the total must not move.")
        let vpAfter = app.revealedSourceRow("VPBank")
        let cashAfter = app.revealedSourceRow("Cash")
        XCTAssertNotEqual(vpBefore, vpAfter, "VPBank balance did not drop after the transfer (stale Overview store).")
        XCTAssertNotEqual(cashBefore, cashAfter, "Cash balance did not rise after the transfer (stale Overview store).")

        // PERSISTENCE — the moved balances survive a cold start.
        app.relaunchPreservingData()
        XCTAssertEqual(vpAfter, app.revealedSourceRow("VPBank"), "VPBank balance reverted after relaunch.")
        XCTAssertEqual(cashAfter, app.revealedSourceRow("Cash"), "Cash balance reverted after relaunch.")
    }
}
