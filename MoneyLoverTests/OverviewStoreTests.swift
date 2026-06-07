import Testing
import Foundation
import SwiftData
@testable import MoneyLover

@MainActor
@Suite struct OverviewStoreTests {
    private func makeStore() -> (store: OverviewStore, sources: SourceRepository, rates: RatesRepository) {
        let container = try! ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let sources = SourceRepository(context: context)
        let rates = RatesRepository(context: context)
        let store = OverviewStore(
            sources: sources,
            transactions: TransactionRepository(context: context),
            rates: rates,
            goals: GoalRepository(context: context)
        )
        return (store, sources, rates)
    }

    private func account(_ currency: Currency, balance: Int) -> Source {
        Source(
            name: "Acc-\(currency.rawValue)",
            kind: .account,
            currency: currency,
            openingBalance: Money(minorUnits: balance, currency: currency),
            iconName: "banknote"
        )
    }

    @Test func usdAccountShowsVNDEquivalent() throws {
        let (store, sources, rates) = makeStore()
        try sources.add(account(.usd, balance: 1_100_00)) // $1,100
        try rates.upsert(key: "fx.USD", value: 25_500, isManual: true, fetchedAt: .now)
        store.load()

        let usd = try #require(store.accounts.first)
        // $1,100 × 25,500 = ₫28,050,000
        #expect(store.vndEquivalent(for: usd) == Money(minorUnits: 28_050_000, currency: .vnd))
    }

    @Test func vndAccountHasNoEquivalent() throws {
        let (store, sources, _) = makeStore()
        try sources.add(account(.vnd, balance: 80_000_000))
        store.load()

        let vnd = try #require(store.accounts.first)
        #expect(store.vndEquivalent(for: vnd) == nil)
    }

    @Test func foreignAccountWithMissingRateHasNoEquivalent() throws {
        // Without an FX rate the value would be a misleading ₫0 — hide it instead.
        let (store, sources, _) = makeStore()
        try sources.add(account(.sgd, balance: 2_000_00))
        store.load()

        let sgd = try #require(store.accounts.first)
        #expect(store.vndEquivalent(for: sgd) == nil)
    }
}
