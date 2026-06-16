import Foundation

/// Maps between the persistence `SourceRecord` and the pure domain `Source`.
/// Kept free of `ModelContext` so it is unit-testable without SwiftData.
extension SourceRecord {
    convenience init(domain s: Source) {
        self.init(
            id: s.id,
            name: s.name,
            kindRaw: s.kind.rawValue,
            currencyRaw: s.currency.rawValue,
            openingMinorUnits: s.openingBalance.minorUnits,
            iconName: s.iconName,
            logoAsset: s.logoAsset,
            holdingQuantity: s.holding?.quantity,
            holdingUnitRaw: s.holding?.unit.rawValue,
            ticker: s.holding?.ticker
        )
    }

    /// Returns the domain value, or nil if persisted raw values are invalid.
    func toDomain() -> Source? {
        guard
            let kind = SourceKind(rawValue: kindRaw),
            let currency = Currency(rawValue: currencyRaw)
        else { return nil }

        var holding: HoldingInfo?
        if let quantity = holdingQuantity, let unitRaw = holdingUnitRaw,
           let unit = HoldingUnit(rawValue: unitRaw) {
            holding = HoldingInfo(quantity: quantity, unit: unit, ticker: ticker)
        }

        return Source(
            id: id,
            name: name,
            kind: kind,
            currency: currency,
            openingBalance: Money(minorUnits: openingMinorUnits, currency: currency),
            iconName: iconName,
            logoAsset: logoAsset,
            holding: holding
        )
    }

    /// Overwrites this record's fields from a domain value (same id).
    func update(from s: Source) {
        name = s.name
        kindRaw = s.kind.rawValue
        currencyRaw = s.currency.rawValue
        openingMinorUnits = s.openingBalance.minorUnits
        iconName = s.iconName
        logoAsset = s.logoAsset
        holdingQuantity = s.holding?.quantity
        holdingUnitRaw = s.holding?.unit.rawValue
        ticker = s.holding?.ticker
    }
}
