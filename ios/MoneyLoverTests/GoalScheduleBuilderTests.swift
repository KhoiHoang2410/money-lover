import Testing
import Foundation
@testable import MoneyLover

@Suite struct GoalScheduleBuilderTests {
    private let jan = YearMonth(year: 2026, month: 1)

    @Test func oneLinePerMonthInTheWindow() {
        let schedule = GoalScheduleBuilder.flatSchedule(
            target: vnd(80_000_000), start: jan, end: YearMonth(year: 2026, month: 8)
        )
        #expect(schedule.count == 8)
        #expect(schedule.map(\.month) == Array(1...8))
        #expect(schedule.allSatisfy { $0.year == 2026 })
    }

    @Test func evenlyDivisibleTargetSplitsFlat() {
        let schedule = GoalScheduleBuilder.flatSchedule(
            target: vnd(80_000_000), start: jan, end: YearMonth(year: 2026, month: 8)
        )
        #expect(schedule.allSatisfy { $0.amount == vnd(10_000_000) })
    }

    @Test func scheduleAlwaysSumsExactlyToTarget() {
        // A target that does not divide evenly across 7 months: the remainder must still land.
        let target = vnd(100)
        let schedule = GoalScheduleBuilder.flatSchedule(
            target: target, start: jan, end: YearMonth(year: 2026, month: 7)
        )
        let total = schedule.reduce(0) { $0 + $1.amount.minorUnits }
        #expect(total == target.minorUnits)
    }

    @Test func remainderSpreadsOnePerEarliestMonths() {
        // 100 đồng over 7 months → base 14, remainder 2 → first two months get 15, rest 14.
        let schedule = GoalScheduleBuilder.flatSchedule(
            target: vnd(100), start: jan, end: YearMonth(year: 2026, month: 7)
        )
        #expect(schedule.map { $0.amount.minorUnits } == [15, 15, 14, 14, 14, 14, 14])
    }

    @Test func singleMonthWindowGetsWholeTarget() {
        let schedule = GoalScheduleBuilder.flatSchedule(target: vnd(5_000_000), start: jan, end: jan)
        #expect(schedule.count == 1)
        #expect(schedule.first?.amount == vnd(5_000_000))
    }

    @Test func emptyWhenEndPrecedesStart() {
        let schedule = GoalScheduleBuilder.flatSchedule(
            target: vnd(5_000_000), start: YearMonth(year: 2026, month: 6), end: jan
        )
        #expect(schedule.isEmpty)
    }

    @Test func emptyWhenTargetNotPositive() {
        #expect(GoalScheduleBuilder.flatSchedule(target: vnd(0), start: jan, end: jan).isEmpty)
    }
}
