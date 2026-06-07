import Foundation
import SwiftData

/// Erases every persisted record across all `AppSchema` models in one save. The user-facing
/// "Delete all data" action (Config) calls this — it is irreversible, so the UI gates it behind
/// an explicit, time-delayed confirmation. Unlike `SampleData.clear`, this ships in release builds.
@MainActor
enum DataReset {
    static func eraseAll(into context: ModelContext) throws {
        // Delete object-by-object rather than via `context.delete(model:)`: the bulk form bypasses
        // the context's change tracking, so live `@Query` views (Overview, Calendar…) don't refresh
        // until relaunch. Per-object deletes notify observers, wiping every surface immediately.
        try eraseEach(TransactionRecord.self, from: context)
        try eraseEach(SourceRecord.self, from: context)
        try eraseEach(EnvelopeRecord.self, from: context)
        try eraseEach(RateRecord.self, from: context)
        try eraseEach(GoalRecord.self, from: context)
        try context.save()
    }

    private static func eraseEach<T: PersistentModel>(_ type: T.Type, from context: ModelContext) throws {
        for record in try context.fetch(FetchDescriptor<T>()) {
            context.delete(record)
        }
    }
}
