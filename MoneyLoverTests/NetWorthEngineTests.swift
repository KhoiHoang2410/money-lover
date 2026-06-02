import Testing
import Foundation
@testable import MoneyLover

@Suite struct NetWorthEngineTests {
    private let rates = Rates(fx: [.vnd: 1, .usd: 25_500], goldPerChi: 15_950_000, stock: [:])

    @Test func assetDebtAndNet() {
        let mb = Source(name: "MB", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "b")
        let card = Source(name: "Card", kind: .creditCard, currency: .vnd, openingBalance: .zero(.vnd), iconName: "c")
        let gold = Source(name: "Gold", kind: .holding, currency: .vnd, openingBalance: .zero(.vnd), iconName: "g",
                          holding: HoldingInfo(quantity: 5, unit: .chi))

        let entries: [(source: Source, balance: Money)] = [
            (mb, Money(minorUnits: 80_000_000, currency: .vnd)),
            (gold, .zero(.vnd)),                                  // valued via quantity → 79,750,000
            (card, Money(minorUnits: -18_300_000, currency: .vnd))
        ]
        let nw = NetWorthEngine.compute(entries: entries, rates: rates)
        #expect(nw.asset == Money(minorUnits: 159_750_000, currency: .vnd)) // 80M + 79.75M
        #expect(nw.debt == Money(minorUnits: -18_300_000, currency: .vnd))
        #expect(nw.net == Money(minorUnits: 141_450_000, currency: .vnd))
    }

    @Test func multipleCreditCardsAggregateIntoDebt() {
        let card1 = Source(name: "Visa", kind: .creditCard, currency: .vnd, openingBalance: .zero(.vnd), iconName: "c")
        let card2 = Source(name: "Amex", kind: .creditCard, currency: .vnd, openingBalance: .zero(.vnd), iconName: "c")
        let mb = Source(name: "MB", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "b")
        let entries: [(source: Source, balance: Money)] = [
            (mb, Money(minorUnits: 50_000_000, currency: .vnd)),
            (card1, Money(minorUnits: -5_000_000, currency: .vnd)),
            (card2, Money(minorUnits: -3_000_000, currency: .vnd))
        ]
        let nw = NetWorthEngine.compute(entries: entries, rates: rates)
        #expect(nw.asset == Money(minorUnits: 50_000_000, currency: .vnd))
        #expect(nw.debt == Money(minorUnits: -8_000_000, currency: .vnd)) // both cards aggregated
        #expect(nw.net == Money(minorUnits: 42_000_000, currency: .vnd))  // asset − debt
    }

    @Test func mixedCurrencyNetConvertsViaRates() {
        let mb = Source(name: "MB", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "b")
        let wise = Source(name: "Wise", kind: .account, currency: .usd, openingBalance: .zero(.usd), iconName: "w")
        let card = Source(name: "Card", kind: .creditCard, currency: .usd, openingBalance: .zero(.usd), iconName: "c")
        let entries: [(source: Source, balance: Money)] = [
            (mb, Money(minorUnits: 80_000_000, currency: .vnd)),       // ₫80,000,000
            (wise, Money(minorUnits: 1_000_00, currency: .usd)),       // $1,000 × 25,500 = ₫25,500,000
            (card, Money(minorUnits: -200_00, currency: .usd))         // -$200 × 25,500 = -₫5,100,000
        ]
        let nw = NetWorthEngine.compute(entries: entries, rates: rates)
        #expect(nw.asset == Money(minorUnits: 105_500_000, currency: .vnd)) // 80M + 25.5M
        #expect(nw.debt == Money(minorUnits: -5_100_000, currency: .vnd))
        #expect(nw.net == Money(minorUnits: 100_400_000, currency: .vnd))   // 105.5M − 5.1M
    }

    @Test func emptyIsZero() {
        let nw = NetWorthEngine.compute(entries: [], rates: rates)
        #expect(nw.asset.isZero && nw.debt.isZero && nw.net.isZero)
    }

    @Test func goalBalancesCountAsAsset() {
        // Funding a goal moves money from an Account to a Goal: net worth is unchanged.
        // Before: account holds 100M. After: account 60M + goal 40M = same 100M asset.
        let mb = Source(name: "MB", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "b")
        let entries: [(source: Source, balance: Money)] = [(mb, Money(minorUnits: 60_000_000, currency: .vnd))]
        let nw = NetWorthEngine.compute(
            entries: entries, rates: rates,
            goalBalances: [Money(minorUnits: 40_000_000, currency: .vnd)]
        )
        #expect(nw.asset == Money(minorUnits: 100_000_000, currency: .vnd))
        #expect(nw.net == Money(minorUnits: 100_000_000, currency: .vnd))
    }
}
