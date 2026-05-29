import Testing
import Foundation
@testable import MoneyLover

@Suite struct GoalTrackerTests {
    private let cal = Calendar(identifier: .gregorian)
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }
    private func sched(_ y: Int, _ m: Int, _ millions: Int) -> ScheduledContribution {
        ScheduledContribution(year: y, month: m, amount: vnd(millions * 1_000_000))
    }

    // House: Jan/Feb/Mar 100M, May 150M, Jul/Aug/Sep 100M (note the April + post-Sep gaps).
    private var house: Goal {
        Goal(name: "House", iconName: "house", target: vnd(3_000_000_000), targetDate: date(2026, 12, 31),
             schedule: [sched(2026,1,100), sched(2026,2,100), sched(2026,3,100),
                        sched(2026,5,150), sched(2026,7,100), sched(2026,8,100), sched(2026,9,100)])
    }

    @Test func expectedByEndOfMarchIs300M() {
        #expect(GoalTracker.expectedByToday(schedule: house.schedule, asOf: date(2026,3,31), calendar: cal) == vnd(300_000_000))
    }

    @Test func aheadWhenActualAboveExpected() {
        let p = GoalTracker.progress(goal: house, actual: vnd(320_000_000), asOf: date(2026,3,31), calendar: cal)
        #expect(p.pct > 0)
    }

    @Test func behindWhenActualBelowExpected() {
        let p = GoalTracker.progress(goal: house, actual: vnd(250_000_000), asOf: date(2026,3,31), calendar: cal)
        #expect(p.pct < 0)
    }

    @Test func exactlyOnPlanIsZeroPercent() {
        let p = GoalTracker.progress(goal: house, actual: vnd(300_000_000), asOf: date(2026,3,31), calendar: cal)
        #expect(p.pct == 0)
    }

    @Test func beforeFirstScheduledMonthExpectsZeroAndNoDivideByZero() {
        let p = GoalTracker.progress(goal: house, actual: vnd(0), asOf: date(2025,12,31), calendar: cal)
        #expect(p.expected.isZero)
        #expect(p.pct == 0)
    }

    @Test func afterAllMonthsSumsWholeSchedule() {
        #expect(GoalTracker.expectedByToday(schedule: house.schedule, asOf: date(2026,12,31), calendar: cal) == vnd(750_000_000))
    }

    @Test func fractionOfTargetClampsToOne() {
        let p = GoalTracker.progress(goal: house, actual: vnd(1_500_000_000), asOf: date(2026,3,31), calendar: cal)
        #expect(p.fractionOfTarget == 0.5)
        let done = GoalTracker.progress(goal: house, actual: vnd(9_000_000_000), asOf: date(2026,3,31), calendar: cal)
        #expect(done.fractionOfTarget == 1)
    }

    // MARK: - Contributions derived from the transfer ledger (ADR-0007)

    private func contribution(_ goalID: UUID, _ minor: Int, _ day: Int) -> Transaction {
        Transaction(date: date(2026, 1, day), kind: .transfer, amount: vnd(minor), sourceID: UUID(), goalID: goalID)
    }

    @Test func contributedSumsOnlyMatchingGoalTransfers() {
        let g = UUID(), other = UUID()
        let txns = [
            contribution(g, 100_000_000, 1),
            contribution(other, 50_000_000, 2),                                  // different goal
            contribution(g, 20_000_000, 3),
            Transaction(kind: .expense, amount: vnd(9_000_000), sourceID: UUID()) // not a contribution
        ]
        #expect(GoalTracker.contributed(goalID: g, transactions: txns) == vnd(120_000_000))
    }

    @Test func contributedIsZeroWithNoTransfers() {
        #expect(GoalTracker.contributed(goalID: UUID(), transactions: []).isZero)
    }

    @Test func contributionsAreOldestFirst() {
        let g = UUID()
        let txns = [contribution(g, 30_000_000, 9), contribution(g, 10_000_000, 2)]
        let result = GoalTracker.contributions(goalID: g, transactions: txns)
        #expect(result.map(\.amount) == [vnd(10_000_000), vnd(30_000_000)])
    }

    // MARK: - Schedule status (cumulative)

    @Test func scheduleStatusFundsLinesInOrderThenStops() {
        // 250M contributed covers Jan(100) + Feb(100); Mar(100, cumulative 300) not yet met.
        let schedule = house.schedule
        let status = GoalTracker.scheduleStatus(
            schedule: schedule, contributed: vnd(250_000_000), asOf: date(2026, 2, 15), calendar: cal
        )
        let byMonth = Dictionary(uniqueKeysWithValues: schedule.map { ($0.month, status[$0.id]) })
        #expect(byMonth[1] == .funded)
        #expect(byMonth[2] == .funded)
        #expect(byMonth[3] == .pending)   // March is the current month, not yet covered
    }

    @Test func pastUnfundedLineIsMissed() {
        // As of May, Jan covered (100) but Feb (cumulative 200) unmet and already passed → missed.
        let schedule = house.schedule
        let status = GoalTracker.scheduleStatus(
            schedule: schedule, contributed: vnd(120_000_000), asOf: date(2026, 5, 10), calendar: cal
        )
        let byMonth = Dictionary(uniqueKeysWithValues: schedule.map { ($0.month, status[$0.id]) })
        #expect(byMonth[1] == .funded)
        #expect(byMonth[2] == .missed)
        #expect(byMonth[7] == .pending)   // future month
    }

    @Test func fullyFundedAllLinesGreen() {
        let status = GoalTracker.scheduleStatus(
            schedule: house.schedule, contributed: vnd(750_000_000), asOf: date(2026, 5, 10), calendar: cal
        )
        #expect(status.values.allSatisfy { $0 == .funded })
    }

    @Test func currentMonthUnderfundedIsDueNotMissed() {
        // As of May, Jan–Mar covered (300) but May (cumulative 450) unmet → May is the current
        // month, so it is `due` (still fundable), not `missed`.
        let schedule = house.schedule
        let status = GoalTracker.scheduleStatus(
            schedule: schedule, contributed: vnd(360_000_000), asOf: date(2026, 5, 10), calendar: cal
        )
        let byMonth = Dictionary(uniqueKeysWithValues: schedule.map { ($0.month, status[$0.id]) })
        #expect(byMonth[3] == .funded)
        #expect(byMonth[5] == .due)
        #expect(byMonth[7] == .pending)
    }

    @Test func shortfallIsPerLineAllocatedOldestFirst() {
        // 360M fills Jan(100)+Feb(100)+Mar(100)=300, leaving 60 toward May(150) → May short by 90.
        let schedule = house.schedule
        let short = GoalTracker.shortfalls(schedule: schedule, contributed: vnd(360_000_000))
        let byMonth = Dictionary(uniqueKeysWithValues: schedule.map { ($0.month, short[$0.id]) })
        #expect(byMonth[3] == vnd(0))
        #expect(byMonth[5] == vnd(90_000_000))
        #expect(byMonth[7] == vnd(100_000_000))
    }

    @Test func shortfallIsZeroWhenFullyFunded() {
        let short = GoalTracker.shortfalls(schedule: house.schedule, contributed: vnd(750_000_000))
        #expect(short.values.allSatisfy { $0 == vnd(0) })
    }
}
