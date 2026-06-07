import XCTest

/// The amount fields in the Add-transaction and Add-source flows group thousands live as the user
/// types (e.g. "1,000,000" / "1.000.000"), instead of the raw "1000000" the old `.number` field
/// showed. Locale-agnostic assertion: the visible value keeps the same digits but gains a non-digit
/// grouping separator. Unit coverage of the formatter itself lives in `AmountInputFormatterTests`.
final class AmountGroupingUITests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testTransactionAmountGroupsThousandsWhileTyping() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Add")
        app.element(A11y.Input.addTransaction).tap()
        XCTAssertTrue(app.navigationBars["Add transaction"].waitForExistence(timeout: 5))

        app.typeInField(A11y.Txn.amount, "1000000")
        app.assertGrouped(A11y.Txn.amount, digits: "1000000")
    }

    func testOpeningBalanceGroupsThousandsWhileTyping() {
        let app = XCUIApplication.launchSeeded()
        app.selectTab("Config")
        app.element(A11y.Config.sources).tap()
        app.element(A11y.Source.add).tap()
        XCTAssertTrue(app.navigationBars["Add source"].waitForExistence(timeout: 5))

        app.typeInField(A11y.Source.openingBalance, "2500000")
        app.assertGrouped(A11y.Source.openingBalance, digits: "2500000")
    }
}

private extension XCUIApplication {
    /// Assert the field shows exactly `digits` once grouping separators are stripped, and that at
    /// least one grouping separator was inserted — proving live grouping regardless of locale.
    func assertGrouped(_ identifier: String, digits expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Field '\(identifier)' not found", file: file, line: line)
        let shown = (field.value as? String) ?? ""
        let onlyDigits = shown.filter(\.isNumber)
        XCTAssertEqual(onlyDigits, expected, "Digits changed during grouping: '\(shown)'", file: file, line: line)
        XCTAssertTrue(shown.contains { !$0.isNumber },
                      "Amount '\(shown)' has no grouping separator — it was not grouped", file: file, line: line)
    }
}
