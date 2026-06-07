import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// `DataReset.eraseAll` wipes every `AppSchema` model in one save — the engine behind the
/// irreversible "Delete all data" action.
@MainActor
@Suite struct DataResetTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func eraseAllRemovesEveryModel() throws {
        let context = try makeContext()
        let sources = SourceRepository(context: context)
        let transactions = TransactionRepository(context: context)
        let envelopes = EnvelopeRepository(context: context)
        let rates = RatesRepository(context: context)
        let goals = GoalRepository(context: context)

        let account = Source(name: "Acc", kind: .account, currency: .vnd, openingBalance: .zero(.vnd), iconName: "banknote.fill")
        try sources.add(account)
        try transactions.add(Transaction(date: .now, kind: .expense, amount: Money(minorUnits: 1_000, currency: .vnd), sourceID: account.id))
        try envelopes.add(Envelope(name: "Food", iconName: "fork.knife", allocation: Money(minorUnits: 5_000, currency: .vnd)))
        try rates.upsert(key: "fx.USD", value: 25_500, isManual: false, fetchedAt: .now)
        try goals.add(Goal(name: "House", iconName: "house.fill", target: Money(minorUnits: 9_000, currency: .vnd), targetDate: .now))

        // Sanity: the store is populated before the wipe.
        #expect(try sources.all().isEmpty == false)

        try DataReset.eraseAll(into: context)

        #expect(try sources.all().isEmpty)
        #expect(try transactions.all().isEmpty)
        #expect(try envelopes.all().isEmpty)
        #expect(try goals.all().isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<RateRecord>()) == 0)
    }

    @Test func eraseAllOnEmptyStoreIsANoOp() throws {
        let context = try makeContext()
        try DataReset.eraseAll(into: context)
        #expect(try SourceRepository(context: context).all().isEmpty)
    }
}
