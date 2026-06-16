import Foundation

/// A dated contribution toward a Goal (base currency VND). Pure domain value type, derived from
/// the `.transfer` transactions that fund the Goal (ADR-0007) — it is not persisted on its own.
struct Contribution: Identifiable, Hashable, Sendable {
    let id: UUID
    var goalID: UUID
    var date: Date
    var amount: Money
    /// The funding transfer's note, shown as the contribution's description.
    var note: String

    init(id: UUID = UUID(), goalID: UUID, date: Date, amount: Money, note: String = "") {
        self.id = id
        self.goalID = goalID
        self.date = date
        self.amount = amount
        self.note = note
    }
}
