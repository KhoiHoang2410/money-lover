import Foundation
import SwiftData

/// A cached or manually-overridden rate. Keys: "fx.USD", "fx.SGD", "gold", "stock.<TICKER>".
@Model
final class RateRecord {
    @Attribute(.unique) var key: String
    var value: Decimal
    var isManual: Bool
    var fetchedAt: Date

    init(key: String, value: Decimal, isManual: Bool, fetchedAt: Date) {
        self.key = key
        self.value = value
        self.isManual = isManual
        self.fetchedAt = fetchedAt
    }
}
