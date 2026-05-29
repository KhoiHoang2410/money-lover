import Foundation

/// One envelope's contribution to a month-end sweep.
struct MonthEndLine: Sendable, Identifiable {
    let envelope: Envelope
    /// allocation − spent (positive = surplus swept in, negative = overspend deducted).
    let leftover: Money
    var id: UUID { envelope.id }
}

/// The result of computing a month-end sweep: per-envelope leftovers and the net change to the Reserve.
struct MonthEndOutcome: Sendable {
    let lines: [MonthEndLine]
    let reserveDelta: Money
}
