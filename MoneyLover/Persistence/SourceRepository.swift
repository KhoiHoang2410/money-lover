import Foundation
import SwiftData

/// Reads and writes `Source` values, mapping to/from SwiftData records.
@MainActor
final class SourceRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [Source] {
        let descriptor = FetchDescriptor<SourceRecord>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func add(_ source: Source) throws {
        context.insert(SourceRecord(domain: source))
        try context.save()
    }

    func update(_ source: Source) throws {
        try stageUpdate(source)
        try context.save()
    }

    /// Applies an update (or insert if absent) to the shared context **without saving**, so a caller
    /// can batch it with other writes into a single `save()` — one atomic commit, one `didSave`.
    /// Used by Backfill to restate an opening balance and add its transaction together (ADR-0012).
    func stageUpdate(_ source: Source) throws {
        let id = source.id
        let descriptor = FetchDescriptor<SourceRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else {
            context.insert(SourceRecord(domain: source))
            return
        }
        record.update(from: source)
    }

    /// Commits writes staged via `stageUpdate` (and any other pending change on the shared context).
    func save() throws {
        try context.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<SourceRecord>(predicate: #Predicate { $0.id == id })
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }
}
