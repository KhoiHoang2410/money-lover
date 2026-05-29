import Foundation

/// A money movement. Pure domain value type; persistence maps to/from `TransactionRecord`.
///
/// `amount` is a positive magnitude for expense/income/transfer; for adjustment it may be signed.
/// `affectsBalance` is false for Backfill (informational) entries (slice 12).
struct Transaction: Identifiable, Hashable, Sendable {
    let id: UUID
    var date: Date
    var kind: TransactionKind
    var amount: Money
    /// The source this affects (the "from" source for a transfer).
    var sourceID: UUID
    /// The "to" source, for transfers only.
    var destinationID: UUID?
    /// Amount received at the destination, for a cross-currency transfer (nil ⇒ same as `amount`).
    var destinationAmount: Money?
    /// Computed cost of a cross-currency transfer, in the destination currency.
    var fee: Money?
    var note: String
    /// The envelope this expense draws from (slice 04).
    var envelopeID: UUID?
    /// False for informational Backfill entries that must not move the current balance.
    var affectsBalance: Bool

    init(
        id: UUID = UUID(),
        date: Date = .now,
        kind: TransactionKind,
        amount: Money,
        sourceID: UUID,
        destinationID: UUID? = nil,
        destinationAmount: Money? = nil,
        fee: Money? = nil,
        note: String = "",
        envelopeID: UUID? = nil,
        affectsBalance: Bool = true
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.amount = amount
        self.sourceID = sourceID
        self.destinationID = destinationID
        self.destinationAmount = destinationAmount
        self.fee = fee
        self.note = note
        self.envelopeID = envelopeID
        self.affectsBalance = affectsBalance
    }
}
