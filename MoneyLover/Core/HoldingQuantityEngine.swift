import Foundation

/// Derives a Holding's live quantity from its opening quantity and the Invest trades that touch it.
///
/// Live quantity = opening quantity + Σ Buys − Σ Sells — the `current = opening + Σ transactions`
/// invariant applied to units instead of money (ADR-0010). Pure.
enum HoldingQuantityEngine {
    /// The signed unit delta an Invest applies to the Holding `id`, or nil if it doesn't touch it.
    /// A Buy adds units, a Sell removes them. `sourceID` is the Account, `destinationID` the Holding.
    static func unitDelta(of t: Transaction, forHolding id: UUID) -> Decimal? {
        guard t.kind == .invest, t.affectsBalance, t.destinationID == id,
              let quantity = t.tradeQuantity, let direction = t.tradeDirection
        else { return nil }
        return direction == .buy ? quantity : -quantity
    }

    /// A Holding's live quantity: its opening quantity plus the net of all Invest trades on it.
    /// Returns 0 for a non-Holding source.
    static func liveQuantity(of source: Source, transactions: [Transaction]) -> Decimal {
        guard let opening = source.holding?.quantity else { return 0 }
        return transactions.reduce(opening) { running, t in
            running + (unitDelta(of: t, forHolding: source.id) ?? 0)
        }
    }

    /// The same source with its Holding quantity replaced by the live quantity, so the Valuator
    /// values current units. Non-Holding sources are returned unchanged.
    static func resolved(_ source: Source, transactions: [Transaction]) -> Source {
        guard source.kind == .holding, var holding = source.holding else { return source }
        holding.quantity = liveQuantity(of: source, transactions: transactions)
        var resolved = source
        resolved.holding = holding
        return resolved
    }
}
