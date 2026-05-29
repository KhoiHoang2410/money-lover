import Foundation

/// A dated contribution toward a Goal (base currency VND). Pure domain value type, derived from
/// the `.transfer` transactions that fund the Goal (ADR-0007) — it is not persisted on its own.
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
