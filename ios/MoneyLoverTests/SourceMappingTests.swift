import Testing
import Foundation
@testable import MoneyLover

@Suite struct SourceMappingTests {
    @Test func accountRoundTrips() {
        let source = Source(
            name: "VPBank",
            kind: .account,
            currency: .vnd,
            openingBalance: Money(minorUnits: 12_500_000, currency: .vnd),
            iconName: "banknote.fill",
            logoAsset: "vpbank"
        )
        let restored = SourceRecord(domain: source).toDomain()
        #expect(restored == source)
    }

    @Test func holdingRoundTrips() {
        let source = Source(
            name: "Gold SJC",
            kind: .holding,
            currency: .vnd,
            openingBalance: Money(minorUnits: 0, currency: .vnd),
            iconName: "seal.fill",
            holding: HoldingInfo(quantity: 5, unit: .chi)
        )
        let restored = SourceRecord(domain: source).toDomain()
        #expect(restored == source)
    }

    @Test func creditCardLiabilityRoundTrips() {
        let source = Source(
            name: "VPBank Credit",
            kind: .creditCard,
            currency: .vnd,
            openingBalance: Money(minorUnits: -18_300_000, currency: .vnd),
            iconName: "creditcard.fill"
        )
        let restored = SourceRecord(domain: source).toDomain()
        #expect(restored?.kind.isLiability == true)
        #expect(restored == source)
    }

    @Test func invalidRawValuesReturnNil() {
        let record = SourceRecord(
            id: UUID(), name: "Broken", kindRaw: "nonsense", currencyRaw: "VND",
            openingMinorUnits: 0, iconName: "x", logoAsset: nil,
            holdingQuantity: nil, holdingUnitRaw: nil, ticker: nil
        )
        #expect(record.toDomain() == nil)
    }
}
