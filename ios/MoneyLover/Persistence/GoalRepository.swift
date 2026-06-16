import Foundation
import SwiftData

/// Reads and writes `Goal`s and their contributions.
@MainActor
final class GoalRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func all() throws -> [Goal] {
        let descriptor = FetchDescriptor<GoalRecord>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func add(_ goal: Goal) throws {
        context.insert(GoalRecord(domain: goal))
        try context.save()
    }

    /// Deletes a Goal and reverses its funding: the `.transfer` Contributions are removed, so the
    /// money returns to the Accounts they debited (ADR-0007 — cancelling a Goal un-earmarks it).
    func delete(id: UUID) throws {
        let goals = FetchDescriptor<GoalRecord>(predicate: #Predicate { $0.id == id })
        for record in try context.fetch(goals) { context.delete(record) }
        let funding = FetchDescriptor<TransactionRecord>(predicate: #Predicate { $0.goalID == id })
        for record in try context.fetch(funding) { context.delete(record) }
        try context.save()
    }

    /// Funds a Goal: a `.transfer` from a VND Account to the Goal (Account ↓, Goal ↑).
    func addContribution(goalID: UUID, amount: Money, fromAccountID: UUID, date: Date, note: String = "") throws {
        let transfer = Transaction(
            date: date,
            kind: .transfer,
            amount: amount,
            sourceID: fromAccountID,
            note: note,
            goalID: goalID
        )
        context.insert(TransactionRecord(domain: transfer))
        try context.save()
    }

    /// Total contributed toward a goal, in VND — the sum of its funding transfers.
    func totalContributed(goalID: UUID) throws -> Money {
        GoalTracker.contributed(goalID: goalID, transactions: try fundingTransactions(goalID: goalID))
    }

    /// All contributions toward a goal, oldest-first, as domain values.
    func contributions(goalID: UUID) throws -> [Contribution] {
        GoalTracker.contributions(goalID: goalID, transactions: try fundingTransactions(goalID: goalID))
    }

    private func fundingTransactions(goalID: UUID) throws -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionRecord>(predicate: #Predicate { $0.goalID == goalID })
        return try context.fetch(descriptor).compactMap { $0.toDomain() }
    }
}
