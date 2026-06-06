import Testing
import Foundation
@testable import MoneyLover

@Suite struct TransactionMappingTests {
    @Test func expenseRoundTrips() {
        let tx = Transaction(
            kind: .expense,
            amount: Money(minorUnits: 40_000, currency: .vnd),
            sourceID: UUID(),
            note: "Bánh mì · 2 người",
            envelopeID: UUID()
        )
        #expect(TransactionRecord(domain: tx).toDomain() == tx)
    }

    @Test func transferWithDestinationRoundTrips() {
        let tx = Transaction(
            kind: .transfer,
            amount: Money(minorUnits: 5_000_000, currency: .vnd),
            sourceID: UUID(),
            destinationID: UUID()
        )
        #expect(TransactionRecord(domain: tx).toDomain() == tx)
    }

    @Test func informationalFlagRoundTrips() {
        let tx = Transaction(
            kind: .expense,
            amount: Money(minorUnits: 250_000, currency: .vnd),
            sourceID: UUID(),
            affectsBalance: false
        )
        #expect(TransactionRecord(domain: tx).toDomain()?.affectsBalance == false)
    }

    @Test func invalidRawReturnsNil() {
        let record = TransactionRecord(
            id: UUID(), date: .now, kindRaw: "bogus", amountMinorUnits: 0,
            amountCurrencyRaw: "VND", sourceID: UUID(), destinationID: nil,
            note: "", envelopeID: nil, affectsBalance: true
        )
        #expect(record.toDomain() == nil)
    }

    @Test func investRoundTripsTradeFields() {
        let tx = Transaction(
            kind: .invest,
            amount: Money(minorUnits: 21_000_000, currency: .vnd),
            sourceID: UUID(),
            destinationID: UUID(),
            note: "Buy Gold",
            tradeQuantity: Decimal(string: "3.5")!,
            tradeDirection: .buy
        )
        let back = TransactionRecord(domain: tx).toDomain()
        #expect(back == tx)
        #expect(back?.tradeQuantity == Decimal(string: "3.5")!)
        #expect(back?.tradeDirection == .buy)
    }

    @Test func moneyFromMajorRoundsToMinorUnits() {
        #expect(Money(major: Decimal(string: "1.50")!, currency: .usd) == Money(minorUnits: 150, currency: .usd))
        #expect(Money(major: 40_000, currency: .vnd) == Money(minorUnits: 40_000, currency: .vnd))
    }
}
