import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// Feat 5 — editing and deleting transactions. The repository updates in place (same id) and
/// deletes; the stores expose those, and the Calendar derives its add-date and removes rows.
@MainActor
@Suite struct TransactionEditDeleteTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private let account = UUID()

    @Test func updateOverwritesInPlaceKeepingId() throws {
        let repo = TransactionRepository(context: try makeContext())
        let original = makeExpense(Money(minorUnits: 40_000, currency: .vnd), source: account, note: "Coffee")
        try repo.add(original)

        let edited = Transaction(
            id: original.id, date: original.date, kind: .expense,
            amount: Money(minorUnits: 90_000, currency: .vnd), sourceID: account, note: "Lunch"
        )
        try repo.update(edited)

        let all = try repo.all()
        #expect(all.count == 1) // same row, not a duplicate
        #expect(all.first?.id == original.id)
        #expect(all.first?.amount == Money(minorUnits: 90_000, currency: .vnd))
        #expect(all.first?.note == "Lunch")
    }

    @Test func updateMissingIdInserts() throws {
        let repo = TransactionRepository(context: try makeContext())
        let t = makeExpense(Money(minorUnits: 10_000, currency: .vnd), source: account)
        try repo.update(t) // nothing stored yet → insert
        #expect(try repo.all().count == 1)
    }

    @Test func deleteRemovesTheRow() throws {
        let repo = TransactionRepository(context: try makeContext())
        let a = makeExpense(Money(minorUnits: 40_000, currency: .vnd), source: account, note: "A")
        let b = makeExpense(Money(minorUnits: 50_000, currency: .vnd), source: account, note: "B")
        try repo.add(a)
        try repo.add(b)

        try repo.delete(id: a.id)

        let all = try repo.all()
        #expect(all.count == 1)
        #expect(all.first?.note == "B")
    }

    @Test func inputStoreEditPreservesInformationalFlag() throws {
        let context = try makeContext()
        let repo = TransactionRepository(context: context)
        let store = InputStore(
            sources: SourceRepository(context: context),
            transactions: repo,
            envelopes: EnvelopeRepository(context: context)
        )
        // A backfilled (informational) expense edited to a new amount must stay informational.
        let backfill = makeBackfill(amount: Money(minorUnits: 40_000, currency: .vnd), source: account)
        try repo.add(backfill)
        let edited = Transaction(
            id: backfill.id, date: backfill.date, kind: .expense,
            amount: Money(minorUnits: 70_000, currency: .vnd), sourceID: account, affectsBalance: false
        )
        store.update(edited)
        #expect(try repo.all().first?.affectsBalance == false)
    }
}
