import Foundation

/// Reconcile ("update balance"): compares a source's computed Current balance to the
/// real balance the owner re-enters and produces an Adjustment Transaction for any drift.
///
/// Money-correctness rule (PRD): Current balance always equals reality; the plug goes to
/// an explicit Adjustment — never silently into a balance. Equal balances produce nil.
enum ReconcileService {
    /// An Adjustment for the diff between the real balance and the balance computed from
    /// `transactions`, or nil when they already match. The adjustment's `amount` is signed
    /// (`realBalance − computed`) so that applying it brings the computed balance to reality.
    static func adjustment(
        for source: Source,
        transactions: [Transaction],
        realBalance: Money,
        envelopeID: UUID? = nil,
        note: String = "",
        date: Date = .now
    ) throws -> Transaction? {
        let computed = try BalanceEngine.balance(of: source, transactions: transactions)
        let diff = try realBalance.subtracting(computed)
        guard !diff.isZero else { return nil }
        return Transaction(
            date: date,
            kind: .adjustment,
            amount: diff,
            sourceID: source.id,
            note: note,
            envelopeID: envelopeID
        )
    }
}
