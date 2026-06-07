import Foundation

/// A money movement. Pure domain value type; persistence maps to/from `TransactionRecord`.
///
/// `amount` is a positive magnitude for expense/income/transfer; for adjustment it may be signed.
/// `affectsBalance` is false for Backfill (informational) entries (slice 12).
struct Transaction: Identifiable, Hashable, Sendable, Codable {
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
    /// The Goal this transfer funds (ADR-0007). Set only on a Contribution: a `.transfer` from
    /// an Account to a Goal — `sourceID` is the Account, there is no destination Source.
    var goalID: UUID?
    /// Units traded on an Invest (ADR-0010). Set only on `.invest`: `sourceID` is the VND Account,
    /// `destinationID` is the Holding, `amount` is the VND moved (quantity × unit price), and
    /// `tradeDirection` says whether the Holding's quantity rises (buy) or falls (sell).
    var tradeQuantity: Decimal?
    /// Buy or Sell, for an `.invest` transaction. Nil for every other kind.
    var tradeDirection: TradeDirection?
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
        goalID: UUID? = nil,
        tradeQuantity: Decimal? = nil,
        tradeDirection: TradeDirection? = nil,
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
        self.goalID = goalID
        self.tradeQuantity = tradeQuantity
        self.tradeDirection = tradeDirection
        self.affectsBalance = affectsBalance
    }
}
