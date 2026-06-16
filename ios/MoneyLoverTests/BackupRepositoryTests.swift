import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// Feat — export/import at the persistence layer. `export` snapshots every record; `restore` wipes
/// then re-inserts, so importing a file replaces the store's contents.
@MainActor
@Suite struct BackupRepositoryTests {
    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func exportThenRestoreReproducesData() throws {
        let context = try makeContext()
        let account = makeSource(name: "MBBank", currency: .vnd, opening: vnd(80_000_000))
        try SourceRepository(context: context).add(account)
        try TransactionRepository(context: context).add(makeExpense(vnd(40_000), source: account.id))
        try EnvelopeRepository(context: context).add(
            Envelope(name: "Food", iconName: "fork.knife", allocation: vnd(5_000_000), weeklyCap: vnd(300_000))
        )
        try RatesRepository(context: context).upsert(key: "gold", value: 15_950_000, isManual: false, fetchedAt: .now)

        let backup = try BackupRepository(context: context).export()

        // Restore into a separate, empty store and read it back.
        let fresh = try makeContext()
        try BackupRepository(context: fresh).restore(backup)
        let restored = try BackupRepository(context: fresh).export()

        #expect(restored.sources.count == 1)
        #expect(restored.sources.first?.openingBalance == vnd(80_000_000))
        #expect(restored.transactions.count == 1)
        #expect(restored.envelopes.first?.weeklyCap == vnd(300_000))
        #expect(restored.rates.first?.key == "gold")
    }

    @Test func restoreReplacesExistingData() throws {
        let context = try makeContext()
        try SourceRepository(context: context).add(makeSource(name: "Old account"))
        #expect(try SourceRepository(context: context).all().count == 1)

        let empty = DataBackup(exportedAt: .now, sources: [], transactions: [], envelopes: [], goals: [], rates: [])
        try BackupRepository(context: context).restore(empty)

        #expect(try SourceRepository(context: context).all().isEmpty)
    }
}
