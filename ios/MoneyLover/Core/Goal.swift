import Foundation

/// A long-term savings target with a per-month contribution schedule. Amounts are VND.
/// The funding window is month-based — contributions happen monthly, so a Goal runs from a
/// `startMonth` through an `endMonth` rather than to an exact target day (see CONTEXT.md → Goal).
struct Goal: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var iconName: String
    var target: Money
    var startMonth: YearMonth
    var endMonth: YearMonth
    var schedule: [ScheduledContribution]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        target: Money,
        startMonth: YearMonth,
        endMonth: YearMonth,
        schedule: [ScheduledContribution] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.target = target
        self.startMonth = startMonth
        self.endMonth = endMonth
        self.schedule = schedule
    }
}
