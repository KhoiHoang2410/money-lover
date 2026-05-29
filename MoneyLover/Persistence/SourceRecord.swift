import Foundation
import SwiftData

/// SwiftData persistence record for a `Source`. Persistence-only — domain logic uses `Source`.
@Model
final class SourceRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var currencyRaw: String
    var openingMinorUnits: Int
    var iconName: String
    var logoAsset: String?
    var holdingQuantity: Decimal?
    var holdingUnitRaw: String?
    var ticker: String?

    init(
        id: UUID,
        name: String,
        kindRaw: String,
        currencyRaw: String,
        openingMinorUnits: Int,
        iconName: String,
        logoAsset: String?,
        holdingQuantity: Decimal?,
        holdingUnitRaw: String?,
        ticker: String?
    ) {
        self.id = id
        self.name = name
        self.kindRaw = kindRaw
        self.currencyRaw = currencyRaw
        self.openingMinorUnits = openingMinorUnits
        self.iconName = iconName
        self.logoAsset = logoAsset
        self.holdingQuantity = holdingQuantity
        self.holdingUnitRaw = holdingUnitRaw
        self.ticker = ticker
    }
}
