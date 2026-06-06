import Foundation
import SwiftData

/// Reads and writes `Transaction` values, mapping to/from SwiftData records.
@MainActor
final class TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    /// All transactions, newest first.
    func all() throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func add(_ transaction: Transaction) throws {
        context.insert(TransactionRecord(domain: transaction))
        try context.save()
    }

    /// Overwrites the stored transaction with the same id, or inserts it if absent.
    func update(_ transaction: Transaction) throws {
        let id = transaction.id
        let descriptor = FetchDescriptor<TransactionRecord>(predicate: #Predicate { $0.id == id })
        guard let record = try context.fetch(descriptor).first else {
            try add(transaction)
            return
        }
        record.update(from: transaction)
        try context.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<TransactionRecord>(predicate: #Predicate { $0.id == id })
        for record in try context.fetch(descriptor) {
            context.delete(record)
        }
        try context.save()
    }
}
