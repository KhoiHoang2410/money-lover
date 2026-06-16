import Testing
import Foundation
@testable import MoneyLover

/// Locks down `Money` precision and validation: integer minor-units never drift, the
/// 0.1 + 0.2 family stays exact, zero/negative handled, currency mismatch rejected,
/// formatting via FormatStyle with no float artifacts. Catalog: docs/test-cases/03.
@Suite struct MoneyTests {

    // MARK: - minor-unit ⇄ major-unit precision

    @Test func amountForVNDHasNoFraction() {
        #expect(vnd(40_000).amount == Decimal(40_000))
    }

    @Test func amountForUSDScalesByHundred() throws {
        #expect(usd(100).amount == Decimal(1))
        let expected = try #require(Decimal(string: "271.68"))
        #expect(usd(271_68).amount == expected)
    }

    /// Round-trip across all currencies: minor → major → minor never drifts. (03-04)
    @Test(arguments: [
        (Currency.vnd, 40_000, "40000"),
        (.vnd, 1, "1"),
        (.usd, 100, "1.00"),
        (.usd, 1, "0.01"),
        (.usd, 271_68, "271.68"),
        (.sgd, 99, "0.99"),
        (.sgd, 1_000_000_00, "1000000.00"),
    ])
    func minorMajorRoundTrip(currency: Currency, minor: Int, major: String) throws {
        let expected = try #require(Decimal(string: major))
        let money = Money(minorUnits: minor, currency: currency)
        #expect(money.amount == expected)
        // major → minor reconstructs the exact same integer minor units.
        #expect(Money(major: expected, currency: currency).minorUnits == minor)
    }

    /// `Money(major:)` rounds to the currency's minor-unit grid — never stores a float. (03-04)
    @Test(arguments: [
        (Currency.vnd, "40000", 40_000),
        (.vnd, "40000.4", 40_000),   // VND has no fraction → rounds away
        (.vnd, "40000.6", 40_001),
        (.usd, "1.50", 150),
        (.usd, "1.005", 101),        // 100.5 minor → rounds half away from zero
        (.usd, "1.999", 200),
        (.sgd, "0.001", 0),
    ])
    func majorInitRoundsToMinorGrid(currency: Currency, major: String, expectedMinor: Int) throws {
        let value = try #require(Decimal(string: major))
        #expect(Money(major: value, currency: currency).minorUnits == expectedMinor)
    }

    // MARK: - no float drift (the 0.1 + 0.2 family)

    /// 0.10 + 0.20 must be exactly 0.30 — the classic float trap, defeated by integer cents. (03-04)
    @Test(arguments: [
        (10, 20, 30, "0.30"),
        (1, 2, 3, "0.03"),
        (7, 7, 14, "0.14"),
        (99, 1, 100, "1.00"),
        (33, 33, 66, "0.66"),
    ])
    func noFloatDriftOnAwkwardSums(a: Int, b: Int, minorSum: Int, majorSum: String) throws {
        let sum = try usd(a).adding(usd(b))
        let expected = try #require(Decimal(string: majorSum))
        #expect(sum.minorUnits == minorSum)
        #expect(sum.amount == expected)
    }

    /// Building from awkward Decimal literals and summing stays on the cent grid — no 0.30000004. (03-04)
    @Test func noFloatDriftBuildingFromDecimals() throws {
        let a = Money(major: try #require(Decimal(string: "0.10")), currency: .usd)
        let b = Money(major: try #require(Decimal(string: "0.20")), currency: .usd)
        let sum = try a.adding(b)
        #expect(sum.minorUnits == 30)
        #expect(sum.amount == (try #require(Decimal(string: "0.30"))))
    }

    // MARK: - zero / parse-layer rejection (03-03)

    /// Zero is representable and flagged — the value layer the form's `amount > 0` guard relies on. (03-03)
    @Test(arguments: [Currency.vnd, .usd, .sgd])
    func zeroIsZeroAndNotPositive(currency: Currency) {
        let z = Money.zero(currency)
        #expect(z.isZero)
        #expect(z.minorUnits == 0)
        #expect(!z.isNegative)
        #expect(Money(major: 0, currency: currency).isZero)
    }

    /// Purely non-numeric input yields no `Decimal`, so no `Money` is ever built from garbage.
    /// `Decimal(string:)` is lenient (it stops at the first non-numeric char, e.g. "1.2.3"→1.2),
    /// so full input validation lives in the amount field's FormatStyle — covered by the
    /// add-expense UI test (TC-03-03). This locks the value-layer floor: text with no numeric
    /// prefix parses to nothing. (03-03)
    @Test(arguments: ["", "abc", "abc123", "x.y"])
    func nonNumericInputDoesNotParse(raw: String) {
        #expect(Decimal(string: raw) == nil)
    }

    // MARK: - same-currency arithmetic

    @Test func addingSameCurrencySumsMinorUnits() throws {
        let sum = try vnd(100).adding(vnd(250))
        #expect(sum == vnd(350))
    }

    @Test func subtractingSameCurrency() throws {
        let diff = try usd(500).subtracting(usd(200))
        #expect(diff == usd(300))
    }

    @Test func subtractingPastZeroGoesNegative() throws {
        let diff = try usd(200).subtracting(usd(500))
        #expect(diff.minorUnits == -300)
        #expect(diff.isNegative)
    }

    // MARK: - currency mismatch rejected

    @Test func addingDifferentCurrenciesThrows() {
        #expect(throws: MoneyError.currencyMismatch(.vnd, .usd)) {
            try vnd(100).adding(usd(100))
        }
    }

    @Test func subtractingDifferentCurrenciesThrows() {
        #expect(throws: MoneyError.currencyMismatch(.sgd, .vnd)) {
            try sgd(100).subtracting(vnd(100))
        }
    }

    // MARK: - negative & zero handling

    @Test func negatePreservesCurrencyAndFlips() {
        let n = vnd(40_000).negated
        #expect(n == vnd(-40_000))
        #expect(n.isNegative)
        #expect(n.negated == vnd(40_000))
    }

    @Test func zeroAndNegativeFlags() {
        #expect(Money.zero(.vnd).isZero)
        #expect(usd(-1).isNegative)
        #expect(!usd(-1).isZero)
    }

    /// Equality compares both minor units AND currency — same number, different currency ≠ equal.
    @Test func equalityIncludesCurrency() {
        #expect(vnd(100) == vnd(100))
        #expect(vnd(100) != usd(100))
        #expect(usd(100) != usd(101))
    }

    // MARK: - formatting via FormatStyle (no float artifacts)

    /// `formatted` renders the exact `Decimal` amount via FormatStyle: equal Money always formats
    /// identically and an awkward sum carries no float artifacts (asserted on the locale-independent
    /// amount, since the rendered separator/symbol is locale-dependent). (03-04)
    @Test func formattingIsExactAndStable() throws {
        let a = try usd(10).adding(usd(20))            // 0.30
        #expect(a.amount == (try #require(Decimal(string: "0.30"))))
        #expect(a.formatted == usd(30).formatted)
        #expect(a.formatted != usd(31).formatted)
        #expect(!a.formatted.isEmpty)
    }

    @Test func negativeAndZeroFormatWithoutCrashing() {
        // Locale-independent substance: the underlying amount is exact; formatting just renders it.
        #expect(usd(-150).amount == Decimal(string: "-1.50"))
        #expect(Money.zero(.usd).amount == Decimal(0))
        #expect(!usd(-150).formatted.isEmpty)
        #expect(!Money.zero(.usd).formatted.isEmpty)
    }
}
