import Testing
import Foundation
@testable import MoneyLover

/// Locks down `AmountInputFormatter` — the pure logic behind the live thousands-separator display
/// in the Add-transaction and Add-source amount fields. Grouping must match the locale separator
/// (`,` en-US, `.` vi-VN — the same one the Overview shows), the parsed `Decimal` must stay exact,
/// fractions must respect the currency's digit count, and re-feeding the formatter's own output must
/// be a no-op (idempotent), since the view does exactly that on every keystroke.
@Suite struct AmountInputFormatterTests {

    // Deterministic separators, independent of ICU locale data on the test host.
    private func comma(fraction: Int = 2) -> AmountInputFormatter {
        AmountInputFormatter(maximumFractionDigits: fraction, groupingSeparator: ",", decimalSeparator: ".")
    }
    private func dot(fraction: Int = 0) -> AmountInputFormatter {
        AmountInputFormatter(maximumFractionDigits: fraction, groupingSeparator: ".", decimalSeparator: ",")
    }

    // MARK: - Grouping the integer part (the feature)

    @Test func groupsThousandsWithCommaSeparator() {
        let f = comma()
        #expect(f.format("1000") == "1,000")
        #expect(f.format("1000000") == "1,000,000")
        #expect(f.format("865062755") == "865,062,755")
    }

    @Test func groupsThousandsWithLocaleDotSeparator() {
        // VND-style: "." groups, matching the Overview's "₫865.062.755".
        let f = dot()
        #expect(f.format("865062755") == "865.062.755")
        #expect(f.format("1000000") == "1.000.000")
    }

    @Test func shortNumbersAreUngrouped() {
        let f = comma()
        #expect(f.format("0") == "0")
        #expect(f.format("12") == "12")
        #expect(f.format("100") == "100")
        #expect(f.format("999") == "999")
    }

    // MARK: - Idempotency (the view re-feeds output on every keystroke)

    @Test func formattingIsIdempotent() {
        let f = comma()
        #expect(f.format("1,234,567") == "1,234,567")
        #expect(f.format(f.format("1234567")) == "1,234,567")
    }

    @Test func appendingADigitRegroups() {
        // "1,234" + "5" → the field re-feeds "1,2345" and must regroup to "12,345".
        let f = comma()
        #expect(f.format("1,2345") == "12,345")
    }

    // MARK: - Leading zeros

    @Test func dropsLeadingZerosButKeepsASingleZero() {
        let f = comma()
        #expect(f.format("") == "")
        #expect(f.format("00") == "0")
        #expect(f.format("007") == "7")
        #expect(f.format("0100") == "100")
    }

    // MARK: - Fractions

    @Test func keepsFractionUpToTheCurrencyDigitCount() {
        let f = comma(fraction: 2)
        #expect(f.format("1234.5") == "1,234.5")
        #expect(f.format("1234.56") == "1,234.56")
        #expect(f.format("1234.567") == "1,234.56") // truncated, never rounded up
    }

    @Test func bareDecimalSeparatorReadsAsZeroPoint() {
        let f = comma(fraction: 2)
        #expect(f.format(".") == "0.")
        #expect(f.format(".5") == "0.5")
    }

    @Test func vndDropsAnyTypedFraction() {
        // VND has 0 fraction digits — a typed separator and trailing digits are discarded.
        let f = dot(fraction: 0)
        #expect(f.format("1000,5") == "1.000")
        #expect(f.format("1000,") == "1.000")
    }

    // MARK: - Parsed value stays exact

    @Test func valueParsesGroupedInputExactly() throws {
        let f = comma(fraction: 2)
        #expect(f.value("1,000,000") == Decimal(1_000_000))
        #expect(f.value("1,234.56") == (try #require(Decimal(string: "1234.56"))))
        #expect(f.value("") == 0)
        #expect(f.value(".5") == (try #require(Decimal(string: "0.5"))))
    }

    @Test func valueIgnoresGroupingSeparatorRegardlessOfLocale() throws {
        let f = dot(fraction: 0)
        #expect(f.value("865.062.755") == Decimal(865_062_755))
        #expect(f.value("1.000.000") == Decimal(1_000_000))
    }

    /// The display string and the parsed value agree — what the user reads equals what gets saved.
    @Test(arguments: ["1000", "1234567", "50", "0", "999999"])
    func displayAndValueAgree(_ raw: String) {
        let f = comma(fraction: 2)
        let shown = f.format(raw)
        #expect(f.value(shown) == f.value(raw))
    }

    // MARK: - Rendering a known value (initial display)

    @Test func displayForValueGroupsAndBlanksZero() {
        let f = comma(fraction: 2)
        #expect(f.display(for: 0) == "")
        #expect(f.display(for: Decimal(1_234_567)) == "1,234,567")
        #expect(f.display(for: Decimal(string: "1234.5")!) == "1,234.5")
    }

    @Test func displayForValueUsesLocaleSeparators() {
        let f = dot(fraction: 0)
        #expect(f.display(for: Decimal(1_000_000)) == "1.000.000")
    }

    // MARK: - Locale-driven initializer wires the right separators

    @Test func localeInitializerPicksUpGroupingSeparator() {
        let enUS = AmountInputFormatter(maximumFractionDigits: 2, locale: Locale(identifier: "en_US"))
        #expect(enUS.groupingSeparator == ",")
        #expect(enUS.format("1000000") == "1,000,000")
    }
}
