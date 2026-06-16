import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// Guards the store-reload contract the Input form depends on: a `Source` created after the store
/// first loaded must surface on the next `load()`. The transaction form's pickers reload on every
/// appearance precisely so this holds (bug: empty expense source picker after creating an account).
@MainActor
@Suite struct InputStoreTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeStore(_ context: ModelContext) -> InputStore {
        InputStore(
            sources: SourceRepository(context: context),
            transactions: TransactionRepository(context: context),
            envelopes: EnvelopeRepository(context: context),
            goals: GoalRepository(context: context)
        )
    }

    private func cash() -> Source {
        Source(
            name: "Cash", kind: .account, currency: .vnd,
            openingBalance: Money(minorUnits: 100_000, currency: .vnd), iconName: "banknote"
        )
    }

    @Test func loadSurfacesSourcesAddedAfterFirstLoad() throws {
        let context = try makeContext()
        let sources = SourceRepository(context: context)
        let store = makeStore(context)

        store.load()
        #expect(store.sources.isEmpty)

        try sources.add(cash())

        store.load()
        #expect(store.sources.contains { $0.name == "Cash" })
    }

    @Test func reloadReplacesRatherThanAppends() throws {
        let context = try makeContext()
        let sources = SourceRepository(context: context)
        let store = makeStore(context)

        try sources.add(cash())
        store.load()
        store.load()
        #expect(store.sources.count == 1)
    }
}
