import Testing
import Foundation
@testable import MoneyLover

/// End-to-end money correctness for an Invest (ADR-0010): the VND Account moves by quantity × price,
/// the Holding's money balance never moves, and its value tracks the live quantity at market price.
@Suite struct InvestTradeTests {
    private let rates = Rates(fx: [.vnd: 1], goldPerChi: 8_000_000, stock: [:])

    private func setup() -> (account: Source, gold: Source) {
        let account = makeSource(name: "VPBank", kind: .account, currency: .vnd, opening: Money(minorUnits: 100_000_000, currency: .vnd))
        let gold = makeSource(name: "Gold", kind: .holding, holding: HoldingInfo(quantity: 0, unit: .chi))
        return (account, gold)
    }

    @Test func buyDebitsTheAccount() throws {
        let (account, gold) = setup()
        // Buy 3 chỉ @ ₫7,000,000 = ₫21,000,000 out of the account.
        let buy = makeInvest(.buy, quantity: 3, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account.id, holding: gold.id)
        let balance = try BalanceEngine.balance(of: account, transactions: [buy])
        #expect(balance == Money(minorUnits: 79_000_000, currency: .vnd))
    }

    @Test func sellCreditsTheAccount() throws {
        let (account, gold) = setup()
        let sell = makeInvest(.sell, quantity: 2, unitPrice: Money(minorUnits: 9_000_000, currency: .vnd), account: account.id, holding: gold.id)
        // +₫18,000,000 proceeds.
        let balance = try BalanceEngine.balance(of: account, transactions: [sell])
        #expect(balance == Money(minorUnits: 118_000_000, currency: .vnd))
    }

    @Test func holdingMoneyBalanceNeverMoves() throws {
        let (account, gold) = setup()
        let buy = makeInvest(.buy, quantity: 3, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account.id, holding: gold.id)
        // The Holding side carries a quantity delta, not money — its money balance stays at opening (0).
        let balance = try BalanceEngine.balance(of: gold, transactions: [buy])
        #expect(balance == .zero(.vnd))
    }

    @Test func holdingValueTracksLiveQuantityAtMarket() {
        let (account, gold) = setup()
        let buy = makeInvest(.buy, quantity: 3, unitPrice: Money(minorUnits: 7_000_000, currency: .vnd), account: account.id, holding: gold.id)
        // Bought at ₫7M, market is ₫8M/chỉ → 3 × 8,000,000 = ₫24,000,000 (a paper gain).
        let resolved = HoldingQuantityEngine.resolved(gold, transactions: [buy])
        let value = Valuator.valueInVND(source: resolved, balance: .zero(.vnd), rates: rates)
        #expect(value == Money(minorUnits: 24_000_000, currency: .vnd))
    }

}
