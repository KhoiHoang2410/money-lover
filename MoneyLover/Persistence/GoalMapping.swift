import Foundation

/// Maps between `GoalRecord` and the pure domain `Goal` (schedule via JSON).
extension GoalRecord {
    convenience init(domain g: Goal) {
        let data = (try? JSONEncoder().encode(g.schedule)) ?? Data()
        self.init(
            id: g.id,
            name: g.name,
            iconName: g.iconName,
            targetMinorUnits: g.target.minorUnits,
            targetDate: g.targetDate,
            scheduleData: data
        )
    }

    func toDomain() -> Goal {
        let schedule = (try? JSONDecoder().decode([ScheduledContribution].self, from: scheduleData)) ?? []
        return Goal(
            id: id,
            name: name,
            iconName: iconName,
            target: Money(minorUnits: targetMinorUnits, currency: .vnd),
            targetDate: targetDate,
            schedule: schedule
        )
    }

    func update(from g: Goal) {
        name = g.name
        iconName = g.iconName
        targetMinorUnits = g.target.minorUnits
        targetDate = g.targetDate
        scheduleData = (try? JSONEncoder().encode(g.schedule)) ?? Data()
    }
}
