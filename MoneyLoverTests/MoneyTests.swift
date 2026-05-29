import Testing
import Foundation
@testable import MoneyLover

@Suite struct MoneyTests {
    @Test func amountForVNDHasNoFraction() {
        #expect(Money(minorUnits: 40_000, currency: .vnd).amount == Decimal(40_000))
    }

    @Test func amountForUSDScalesByHundred() throws {
        #expect(Money(minorUnits: 100, currency: .usd).amount == Decimal(1))
        let expected = try #require(Decimal(string: "271.68"))
        #expect(Money(minorUnits: 271_68, currency: .usd).amount == expected)
    }

    @Test func addingSameCurrencySumsMinorUnits() throws {
        let sum = try Money(minorUnits: 100, currency: .vnd).adding(Money(minorUnits: 250, currency: .vnd))
        #expect(sum == Money(minorUnits: 350, currency: .vnd))
    }

    @Test func addingDifferentCurrenciesThrows() {
        #expect(throws: MoneyError.self) {
            try Money(minorUnits: 100, currency: .vnd).adding(Money(minorUnits: 100, currency: .usd))
        }
    }

    @Test func subtractingSameCurrency() throws {
        let diff = try Money(minorUnits: 500, currency: .usd).subtracting(Money(minorUnits: 200, currency: .usd))
        #expect(diff == Money(minorUnits: 300, currency: .usd))
    }

    @Test func negatePreservesCurrency() {
        let n = Money(minorUnits: 40_000, currency: .vnd).negated
        #expect(n == Money(minorUnits: -40_000, currency: .vnd))
        #expect(n.isNegative)
    }

    @Test func zeroAndNegativeFlags() {
        #expect(Money.zero(.vnd).isZero)
        #expect(Money(minorUnits: -1, currency: .usd).isNegative)
    }

    @Test func noFloatDrift() throws {
        // 0.10 + 0.20 must equal exactly 0.30 (the classic float trap), via integer cents.
        let sum = try Money(minorUnits: 10, currency: .usd).adding(Money(minorUnits: 20, currency: .usd))
        let expected = try #require(Decimal(string: "0.30"))
        #expect(sum.amount == expected)
        #expect(sum.minorUnits == 30)
    }
}
