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

    @Test func emptyIsZero() {
        let nw = NetWorthEngine.compute(entries: [], rates: rates)
        #expect(nw.asset.isZero && nw.debt.isZero && nw.net.isZero)
    }
}
