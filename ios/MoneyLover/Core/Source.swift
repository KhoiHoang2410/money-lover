import Foundation

/// A place money lives: an Account, a Credit card (Liability), or a Holding.
/// Pure domain value type — persistence maps to/from `SourceRecord`.
struct Source: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var kind: SourceKind
    var currency: Currency
    /// The amount entered when tracking began; anchor for all balance math.
    var openingBalance: Money
    /// SF Symbol name used when there is no bundled logo.
    var iconName: String
    /// Asset-catalog name of a bundled bank/brand logo, if any.
    var logoAsset: String?
    /// Present only for `.holding` sources.
    var holding: HoldingInfo?

    init(
        id: UUID = UUID(),
        name: String,
        kind: SourceKind,
        currency: Currency,
        openingBalance: Money,
        iconName: String,
        logoAsset: String? = nil,
        holding: HoldingInfo? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.currency = currency
        self.openingBalance = openingBalance
        self.iconName = iconName
        self.logoAsset = logoAsset
        self.holding = holding
    }
}
