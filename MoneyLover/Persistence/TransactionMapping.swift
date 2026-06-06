import Foundation

/// Maps between `TransactionRecord` and the pure domain `Transaction`. Free of `ModelContext`.
extension TransactionRecord {
    convenience init(domain t: Transaction) {
        self.init(
            id: t.id,
            date: t.date,
            kindRaw: t.kind.rawValue,
            amountMinorUnits: t.amount.minorUnits,
            amountCurrencyRaw: t.amount.currency.rawValue,
            sourceID: t.sourceID,
            destinationID: t.destinationID,
            destinationAmountMinorUnits: t.destinationAmount?.minorUnits,
            destinationCurrencyRaw: t.destinationAmount?.currency.rawValue,
            feeMinorUnits: t.fee?.minorUnits,
            feeCurrencyRaw: t.fee?.currency.rawValue,
            note: t.note,
            envelopeID: t.envelopeID,
            goalID: t.goalID,
            tradeQuantity: t.tradeQuantity,
            tradeDirectionRaw: t.tradeDirection?.rawValue,
            affectsBalance: t.affectsBalance
        )
    }

    func toDomain() -> Transaction? {
        guard
            let kind = TransactionKind(rawValue: kindRaw),
            let currency = Currency(rawValue: amountCurrencyRaw)
        else { return nil }

        var destinationAmount: Money?
        if let minor = destinationAmountMinorUnits, let raw = destinationCurrencyRaw,
           let destCurrency = Currency(rawValue: raw) {
            destinationAmount = Money(minorUnits: minor, currency: destCurrency)
        }
        var fee: Money?
        if let minor = feeMinorUnits, let raw = feeCurrencyRaw,
           let feeCurrency = Currency(rawValue: raw) {
            fee = Money(minorUnits: minor, currency: feeCurrency)
        }

        return Transaction(
            id: id,
            date: date,
            kind: kind,
            amount: Money(minorUnits: amountMinorUnits, currency: currency),
            sourceID: sourceID,
            destinationID: destinationID,
            destinationAmount: destinationAmount,
            fee: fee,
            note: note,
            envelopeID: envelopeID,
            goalID: goalID,
            tradeQuantity: tradeQuantity,
            tradeDirection: tradeDirectionRaw.flatMap(TradeDirection.init(rawValue:)),
            affectsBalance: affectsBalance
        )
    }
}
