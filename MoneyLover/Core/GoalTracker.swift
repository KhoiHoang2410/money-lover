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
