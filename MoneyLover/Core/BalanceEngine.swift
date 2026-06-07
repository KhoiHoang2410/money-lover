import Foundation

/// Computes a source's current balance from its opening balance and transactions.
///
/// Current balance = Opening balance + Σ of every transaction's signed delta. A Backfill is an
/// ordinary transaction here — it stays current-balance-neutral because its opening balance was
/// restated by the opposite amount when it was recorded (see `InputStore.addBackfill`, ADR-0012).
enum BalanceEngine {
    /// Sums signed deltas (same currency) onto an opening balance.
    static func current(opening: Money, deltas: [Money] = []) throws -> Money {
        try deltas.reduce(opening) { try $0.adding($1) }
    }

    /// Current balance of a source given all transactions in the system.
    static func balance(of source: Source, transactions: [Transaction]) throws -> Money {
        let deltas = transactions.compactMap { signedDelta(of: $0, forSource: source.id) }
        return try current(opening: source.openingBalance, deltas: deltas)
    }

    /// The signed effect a transaction has on the given source, or nil if it doesn't touch it.
    /// Expense subtracts from / adds debt to the charged source; income adds; a transfer subtracts
    /// from its source and adds to its destination.
    private static func signedDelta(of t: Transaction, forSource id: UUID) -> Money? {
        switch t.kind {
        case .expense:
            return t.sourceID == id ? t.amount.negated : nil
        case .income:
            return t.sourceID == id ? t.amount : nil
        case .adjustment:
            return t.sourceID == id ? t.amount : nil
        case .transfer:
            if t.sourceID == id { return t.amount.negated }
            if t.destinationID == id { return t.destinationAmount ?? t.amount }
            return nil
        case .invest:
            // Only the VND Account side (`sourceID`) has a money delta: a Buy spends it, a Sell
            // credits it. The Holding side carries a quantity delta, not money (ADR-0010) —
            // see HoldingQuantityEngine — so it contributes nothing here.
            guard t.sourceID == id, let direction = t.tradeDirection else { return nil }
            return direction == .buy ? t.amount.negated : t.amount
        }
    }
}
