import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// Feat 4 — applying Starter envelopes: adds the chosen ones, skips names that already exist
/// (case-insensitive), and assigns the Reserve only when none exists yet.
@MainActor
@Suite struct StarterEnvelopesTests {
    private func makeStore() throws -> (store: EnvelopesStore, repo: EnvelopeRepository) {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let repo = EnvelopeRepository(context: context)
        let store = EnvelopesStore(envelopes: repo, transactions: TransactionRepository(context: context))
        store.load()
        return (store, repo)
    }

    private func starter(_ name: String) -> StarterEnvelope {
        StarterEnvelope.catalog.first { $0.name == name }!
    }

    @Test func catalogHasExactlyOneReserveDefault() {
        #expect(StarterEnvelope.catalog.filter(\.isReserveDefault).count == 1)
        #expect(StarterEnvelope.catalog.first(where: \.isReserveDefault)?.name == "Savings")
    }

    @Test func applyAddsChosenWithZeroAllocation() throws {
        let (store, _) = try makeStore()
        store.applyStarter([starter("Food & Dining"), starter("Groceries")])
        #expect(store.envelopes.count == 2)
        #expect(store.envelopes.allSatisfy { $0.allocation == .zero(.vnd) })
        #expect(Set(store.envelopes.map(\.name)) == ["Food & Dining", "Groceries"])
    }

    @Test func applySkipsNamesThatAlreadyExistCaseInsensitively() throws {
        let (store, repo) = try makeStore()
        try repo.add(Envelope(name: "  groceries ", iconName: "cart", allocation: .zero(.vnd)))
        store.load()
        store.applyStarter([starter("Groceries"), starter("Food & Dining")])
        // "groceries" already exists (trimmed, lowercased) → only Food & Dining is added.
        let names = store.envelopes.map { StarterEnvelope.key($0.name) }
        #expect(names.contains("food & dining"))
        #expect(names.filter { $0 == "groceries" }.count == 1)
    }

    @Test func applyAssignsSavingsAsReserveWhenNoneExists() throws {
        let (store, _) = try makeStore()
        store.applyStarter([starter("Food & Dining"), starter("Savings")])
        let reserve = store.envelopes.first { $0.isReserve }
        #expect(reserve?.name == "Savings")
    }

    @Test func applyKeepsExistingReserveUntouched() throws {
        let (store, repo) = try makeStore()
        try repo.add(Envelope(name: "Buffer", iconName: "star", allocation: .zero(.vnd), isReserve: true))
        store.load()
        store.applyStarter([starter("Savings")])
        // Savings is added but does NOT steal the Reserve from the pre-existing Buffer.
        #expect(store.envelopes.first { $0.isReserve }?.name == "Buffer")
        #expect(store.envelopes.contains { $0.name == "Savings" && !$0.isReserve })
    }

    @Test func existingNamesAreNormalized() throws {
        let (store, repo) = try makeStore()
        try repo.add(Envelope(name: " Transport ", iconName: "car", allocation: .zero(.vnd)))
        store.load()
        #expect(store.existingNames.contains("transport"))
    }
}
