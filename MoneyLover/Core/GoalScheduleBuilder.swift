import Foundation

/// Builds a Goal's funding Schedule from its window. Pure — no `Date.now`; inject the months.
enum GoalScheduleBuilder {
    /// A flat monthly plan across the inclusive window `[start, end]` that sums **exactly** to
    /// `target`. Each month gets `target / months` (integer minor units); the leftover đồng
    /// (`target − base × months`, always `< months`) is spread one-per-month across the earliest
    /// months, so the schedule's total equals the target to the đồng with no lumpy last line.
    /// Returns `[]` if the window is empty (`end < start`) or `target` is not positive.
    static func flatSchedule(target: Money, start: YearMonth, end: YearMonth) -> [ScheduledContribution] {
        guard end >= start, target.minorUnits > 0 else { return [] }
        let months = start.monthsThrough(end)            // ≥ 1 given the guard
        let base = target.minorUnits / months
        let remainder = target.minorUnits - base * months
        return (0..<months).map { i in
            let ym = start.adding(i)
            let extra = i < remainder ? 1 : 0
            return ScheduledContribution(
                year: ym.year,
                month: ym.month,
                amount: Money(minorUnits: base + extra, currency: target.currency)
            )
        }
    }
}
