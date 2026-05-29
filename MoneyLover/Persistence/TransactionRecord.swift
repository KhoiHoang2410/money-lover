import Foundation
import SwiftData

/// SwiftData persistence record for a `Transaction`. Persistence-only.
@Model
final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var kindRaw: String
    var amountMinorUnits: Int
    var amountCurrencyRaw: String
    var sourceID: UUID
    var destinationID: UUID?
    var destinationAmountMinorUnits: Int?
    var destinationCurrencyRaw: String?
    var feeMinorUnits: Int?
    var feeCurrencyRaw: String?
    var note: String
    var envelopeID: UUID?
    var affectsBalance: Bool

    init(
        id: UUID,
        date: Date,
        kindRaw: String,
        amountMinorUnits: Int,
        amountCurrencyRaw: String,
        sourceID: UUID,
        destinationID: UUID?,
        destinationAmountMinorUnits: Int? = nil,
        destinationCurrencyRaw: String? = nil,
        feeMinorUnits: Int? = nil,
        feeCurrencyRaw: String? = nil,
        note: String,
        envelopeID: UUID?,
        affectsBalance: Bool
    ) {
        self.id = id
        self.date = date
        self.kindRaw = kindRaw
        self.amountMinorUnits = amountMinorUnits
        self.amountCurrencyRaw = amountCurrencyRaw
        self.sourceID = sourceID
        self.destinationID = destinationID
        self.destinationAmountMinorUnits = destinationAmountMinorUnits
        self.destinationCurrencyRaw = destinationCurrencyRaw
        self.feeMinorUnits = feeMinorUnits
        self.feeCurrencyRaw = feeCurrencyRaw
        self.note = note
        self.envelopeID = envelopeID
        self.affectsBalance = affectsBalance
    }
}
