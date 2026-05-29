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
        let id = source.id
        let descriptor = FetchDescriptor<SourceRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else {
            try add(source)
            return
        }
        record.update(from: source)
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
