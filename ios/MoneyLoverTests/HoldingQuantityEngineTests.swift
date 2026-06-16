import Testing
import Foundation
@testable import MoneyLover

/// Holding quantity is derived from Invest trades: live = opening + Σ Buys − Σ Sells (ADR-0010).
@Suite struct HoldingQuantityEngineTests {
    private let account = UUID()

    private func gold(opening: Decimal, unit: HoldingUnit = .chi) -> Source {
        makeSource(name: "Gold", kind: .holding, holding: HoldingInfo(quantity: opening, unit: unit))
    }

    @Test func openingQuantityWithNoTrades() {
        let g = gold(opening: 3)
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: []) == 3)
    }

    @Test func buyAddsUnits() {
        let g = gold(opening: 3)
        let buy = makeInvest(.buy, quantity: 2, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account, holding: g.id)
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: [buy]) == 5)
    }

    @Test func sellRemovesUnits() {
        let g = gold(opening: 3)
        let sell = makeInvest(.sell, quantity: 1, unitPrice: Money(minorUnits: 8_000_000, currency: .vnd), account: account, holding: g.id)
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: [sell]) == 2)
    }

    @Test func buysAndSellsNet() {
        let g = gold(opening: 0)
        let txns = [
            makeInvest(.buy, quantity: 5, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account, holding: g.id),
            makeInvest(.sell, quantity: 2, unitPrice: Money(minorUnits: 8_000_000, currency: .vnd), account: account, holding: g.id),
            makeInvest(.buy, quantity: 1, unitPrice: Money(minorUnits: 7_500_000, currency: .vnd), account: account, holding: g.id)
        ]
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: txns) == 4)
    }

    @Test func fractionalQuantitiesAreExact() {
        let g = gold(opening: 0.5)
        let buy = makeInvest(.buy, quantity: 0.25, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account, holding: g.id)
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: [buy]) == 0.75)
    }

    @Test func tradesForOtherHoldingsAreIgnored() {
        let g = gold(opening: 3)
        let other = UUID()
        let buyOther = makeInvest(.buy, quantity: 10, unitPrice: Money(minorUnits: 50_000, currency: .vnd), account: account, holding: other)
        #expect(HoldingQuantityEngine.liveQuantity(of: g, transactions: [buyOther]) == 3)
    }

    @Test func resolvedReplacesQuantityForValuator() {
        let g = gold(opening: 3)
        let buy = makeInvest(.buy, quantity: 2, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account, holding: g.id)
        let resolved = HoldingQuantityEngine.resolved(g, transactions: [buy])
        #expect(resolved.holding?.quantity == 5)
        // Non-holding sources pass through untouched.
        let acc = makeSource(kind: .account)
        #expect(HoldingQuantityEngine.resolved(acc, transactions: [buy]).holding == nil)
    }
}
