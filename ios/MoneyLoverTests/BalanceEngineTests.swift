import Testing
@testable import MoneyLover

@Suite struct BalanceEngineTests {
    @Test func noDeltasReturnsOpening() throws {
        let opening = Money(minorUnits: 80_000_000, currency: .vnd)
        #expect(try BalanceEngine.current(opening: opening) == opening)
    }

    @Test func sumsSignedDeltas() throws {
        let opening = Money(minorUnits: 80_000_000, currency: .vnd)
        let result = try BalanceEngine.current(
            opening: opening,
            deltas: [
                Money(minorUnits: -40_000, currency: .vnd),
                Money(minorUnits: 10_000_000, currency: .vnd)
            ]
        )
        #expect(result == Money(minorUnits: 89_960_000, currency: .vnd))
    }

    @Test func mismatchedCurrencyDeltaThrows() {
        #expect(throws: MoneyError.self) {
            try BalanceEngine.current(
                opening: Money(minorUnits: 0, currency: .vnd),
                deltas: [Money(minorUnits: 100, currency: .usd)]
            )
        }
    }
}
