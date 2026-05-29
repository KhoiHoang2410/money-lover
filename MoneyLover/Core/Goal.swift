import Foundation

/// A long-term savings target with a per-month contribution schedule. Amounts are VND.
struct Goal: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var iconName: String
    var target: Money
    var targetDate: Date
    var schedule: [ScheduledContribution]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        target: Money,
        targetDate: Date,
        schedule: [ScheduledContribution] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.target = target
        self.targetDate = targetDate
        self.schedule = schedule
    }
}
