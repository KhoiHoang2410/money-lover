import Testing
import Foundation
@testable import MoneyLover

@Suite struct GoalMappingTests {
    @Test func goalRoundTripsThroughRecord() {
        let goal = makeGoal(
            name: "House", iconName: "house.fill", target: vnd(3_000_000_000),
            startMonth: ym(2026, 3), endMonth: ym(2027, 1),
            schedule: [sched(2026, 3, vnd(100_000_000)), sched(2026, 4, vnd(150_000_000))]
        )
        let restored = GoalRecord(domain: goal).toDomain()
        #expect(restored == goal)
    }

    @Test func fundingWindowSurvivesAsMonthIndices() {
        let goal = makeGoal(target: vnd(80_000_000), startMonth: ym(2026, 1), endMonth: ym(2026, 8))
        let record = GoalRecord(domain: goal)
        #expect(record.startMonthIndex == ym(2026, 1).index)
        #expect(record.endMonthIndex == ym(2026, 8).index)
        let restored = record.toDomain()
        #expect(restored.startMonth == ym(2026, 1))
        #expect(restored.endMonth == ym(2026, 8))
    }

    @Test func updateFromRewritesWindowAndSchedule() {
        let original = makeGoal(target: vnd(10_000_000), startMonth: ym(2026, 1), endMonth: ym(2026, 6))
        let record = GoalRecord(domain: original)
        let edited = Goal(
            id: original.id, name: "Goal", iconName: "target", target: vnd(20_000_000),
            startMonth: ym(2026, 2), endMonth: ym(2026, 9),
            schedule: [sched(2026, 2, vnd(20_000_000))]
        )
        record.update(from: edited)
        #expect(record.toDomain() == edited)
    }
}
