import Foundation

/// Pure goal-progress math. Inject the date/calendar for testability.
enum GoalTracker {
    private static func monthIndex(year: Int, month: Int) -> Int {
        year * 12 + (month - 1)
    }

    /// Cumulative scheduled amount due on or before `asOf`.
    static func expectedByToday(schedule: [ScheduledContribution], asOf: Date, calendar: Calendar = .current) -> Money {
        let comps = calendar.dateComponents([.year, .month], from: asOf)
        let todayIndex = monthIndex(year: comps.year ?? 0, month: comps.month ?? 1)
        let total = schedule
            .filter { monthIndex(year: $0.year, month: $0.month) <= todayIndex }
            .reduce(0) { $0 + $1.amount.minorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }

    /// A Goal's balance = the sum of its Contributions, each a `.transfer` carrying its `goalID`.
    static func contributed(goalID: UUID, transactions: [Transaction]) -> Money {
        let total = contributions(goalID: goalID, transactions: transactions)
            .reduce(0) { $0 + $1.amount.minorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }

    /// The Contributions toward a Goal, oldest-first, derived from the transfer ledger.
    static func contributions(goalID: UUID, transactions: [Transaction]) -> [Contribution] {
        transactions
            .filter { $0.kind == .transfer && $0.goalID == goalID }
            .sorted { $0.date < $1.date }
            .map { Contribution(id: $0.id, goalID: goalID, date: $0.date, amount: $0.amount) }
    }

    /// Cumulative status of each Schedule line: **funded** once the total contributed reaches the
    /// scheduled amount due through that month; **missed** if that month has already passed and it
    /// hasn't; **pending** for a current/future month not yet covered. Keyed by line id.
    static func scheduleStatus(
        schedule: [ScheduledContribution],
        contributed: Money,
        asOf: Date,
        calendar: Calendar = .current
    ) -> [UUID: ScheduleStatus] {
        let comps = calendar.dateComponents([.year, .month], from: asOf)
        let nowIndex = monthIndex(year: comps.year ?? 0, month: comps.month ?? 1)
        let ordered = schedule.sorted { monthIndex(year: $0.year, month: $0.month) < monthIndex(year: $1.year, month: $1.month) }
        var result: [UUID: ScheduleStatus] = [:]
        var cumulative = 0
        for line in ordered {
            cumulative += line.amount.minorUnits
            if contributed.minorUnits >= cumulative {
                result[line.id] = .funded
            } else if monthIndex(year: line.year, month: line.month) < nowIndex {
                result[line.id] = .missed
            } else {
                result[line.id] = .pending
            }
        }
        return result
    }

    static func progress(goal: Goal, actual: Money, asOf: Date, calendar: Calendar = .current) -> GoalProgress {
        let expected = expectedByToday(schedule: goal.schedule, asOf: asOf, calendar: calendar)
        let pct = expected.minorUnits == 0
            ? 0
            : Double(actual.minorUnits) / Double(expected.minorUnits) - 1
        let fraction = goal.target.minorUnits == 0
            ? 0
            : max(0, min(1, Double(actual.minorUnits) / Double(goal.target.minorUnits)))
        return GoalProgress(expected: expected, actual: actual, pct: pct, fractionOfTarget: fraction)
    }
}
