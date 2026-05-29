import Foundation

/// A dated contribution toward a Goal (base currency VND). Pure domain value type;
/// persistence maps to/from `ContributionRecord`.
struct Contribution: Identifiable, Hashable, Sendable {
    let id: UUID
    var goalID: UUID
    var date: Date
    var amount: Money

    init(id: UUID = UUID(), goalID: UUID, date: Date, amount: Money) {
        self.id = id
        self.goalID = goalID
        self.date = date
        self.amount = amount
    }
}
