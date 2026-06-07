import Foundation
import SwiftData

/// Gathers every record into a portable `DataBackup` and restores one by replacing the store's
/// contents. Restore wipes then re-inserts in a single `save()`, so the `didSave` notification fires
/// once and every observing store reloads (no relaunch needed).
@MainActor
final class BackupRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// Reads all data into a `DataBackup` snapshot.
    func export(now: Date = .now) throws -> DataBackup {
        let sources = try context.fetch(FetchDescriptor<SourceRecord>()).compactMap { $0.toDomain() }
        let transactions = try context.fetch(FetchDescriptor<TransactionRecord>()).compactMap { $0.toDomain() }
        let envelopes = try context.fetch(FetchDescriptor<EnvelopeRecord>()).map { $0.toDomain() }
        let goals = try context.fetch(FetchDescriptor<GoalRecord>()).map { $0.toDomain() }
        let rates = try context.fetch(FetchDescriptor<RateRecord>()).map {
            DataBackup.Rate(key: $0.key, value: $0.value, isManual: $0.isManual, fetchedAt: $0.fetchedAt)
        }
        return DataBackup(
            exportedAt: now,
            sources: sources,
            transactions: transactions,
            envelopes: envelopes,
            goals: goals,
            rates: rates
        )
    }

    /// Replaces the entire store with the backup's contents.
    func restore(_ backup: DataBackup) throws {
        deleteAll(TransactionRecord.self)
        deleteAll(SourceRecord.self)
        deleteAll(EnvelopeRecord.self)
        deleteAll(RateRecord.self)
        deleteAll(GoalRecord.self)

        for source in backup.sources { context.insert(SourceRecord(domain: source)) }
        for transaction in backup.transactions { context.insert(TransactionRecord(domain: transaction)) }
        for envelope in backup.envelopes { context.insert(EnvelopeRecord(domain: envelope)) }
        for goal in backup.goals { context.insert(GoalRecord(domain: goal)) }
        for rate in backup.rates {
            context.insert(RateRecord(key: rate.key, value: rate.value, isManual: rate.isManual, fetchedAt: rate.fetchedAt))
        }
        try context.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) {
        for record in (try? context.fetch(FetchDescriptor<T>())) ?? [] {
            context.delete(record)
        }
    }
}
