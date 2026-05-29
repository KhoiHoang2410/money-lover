import Foundation

/// Quantity details for a `Source` of kind `.holding` (gold, stock).
/// Its money value is quantity × market price, computed by the Valuator (not here).
struct HoldingInfo: Hashable, Sendable {
    var quantity: Decimal
    var unit: HoldingUnit
    /// HOSE ticker for stock holdings (nil for gold).
    var ticker: String?

    init(quantity: Decimal, unit: HoldingUnit, ticker: String? = nil) {
        self.quantity = quantity
        self.unit = unit
        self.ticker = ticker
    }
}
