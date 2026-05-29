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

    func delete(id: UUID) throws {
        let goals = FetchDescriptor<GoalRecord>(predicate: #Predicate { $0.id == id })
        for record in try context.fetch(goals) { context.delete(record) }
        let contributions = FetchDescriptor<ContributionRecord>(predicate: #Predicate { $0.goalID == id })
        for record in try context.fetch(contributions) { context.delete(record) }
        try context.save()
    }

    func addContribution(goalID: UUID, amount: Money, date: Date) throws {
        context.insert(ContributionRecord(id: UUID(), goalID: goalID, date: date, amountMinorUnits: amount.minorUnits))
        try context.save()
    }

    /// Total contributed toward a goal, in VND.
    func totalContributed(goalID: UUID) throws -> Money {
        let descriptor = FetchDescriptor<ContributionRecord>(predicate: #Predicate { $0.goalID == goalID })
        let total = try context.fetch(descriptor).reduce(0) { $0 + $1.amountMinorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }

    /// All contributions toward a goal, oldest-first, as domain values.
    func contributions(goalID: UUID) throws -> [Contribution] {
        let descriptor = FetchDescriptor<ContributionRecord>(
            predicate: #Predicate { $0.goalID == goalID },
            sortBy: [SortDescriptor(\.date)]
        )
        return try context.fetch(descriptor).map {
            Contribution(id: $0.id, goalID: $0.goalID, date: $0.date, amount: Money(minorUnits: $0.amountMinorUnits, currency: .vnd))
        }
    }
}
