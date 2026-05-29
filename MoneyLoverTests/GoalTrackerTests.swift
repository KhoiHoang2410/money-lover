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
}
