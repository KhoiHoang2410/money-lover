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
}
