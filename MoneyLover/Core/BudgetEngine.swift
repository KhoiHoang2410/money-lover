import Foundation

/// Envelope budgeting math. Works in the base currency (VND).
enum BudgetEngine {
    /// Total spent against an envelope: the sum of expenses assigned to it.
    static func spent(envelopeID: UUID, transactions: [Transaction]) -> Money {
        let total = transactions
            .filter { $0.kind == .expense && $0.envelopeID == envelopeID }
            .reduce(0) { $0 + $1.amount.minorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }

    /// Remaining in an envelope: allocation + carried − spent (negative when overspent).
    static func remaining(envelope: Envelope, transactions: [Transaction]) throws -> Money {
        let base = try envelope.allocation.adding(envelope.carried)
        return try base.subtracting(spent(envelopeID: envelope.id, transactions: transactions))
    }

    /// Computes the month-end sweep: each non-Reserve envelope's leftover (allocation − spent),
    /// and the net change to the Reserve (the sum of those leftovers).
    /// `spentByEnvelope` is the spend per envelope for the closing month (computed by the caller).
    static func monthEnd(envelopes: [Envelope], spentByEnvelope: [UUID: Money]) throws -> MonthEndOutcome {
        var lines: [MonthEndLine] = []
        var delta = Money.zero(.vnd)
        for envelope in envelopes where !envelope.isReserve {
            let spent = spentByEnvelope[envelope.id] ?? .zero(.vnd)
            let leftover = try envelope.allocation.subtracting(spent)
            lines.append(MonthEndLine(envelope: envelope, leftover: leftover))
            delta = try delta.adding(leftover)
        }
        return MonthEndOutcome(lines: lines, reserveDelta: delta)
    }
}
