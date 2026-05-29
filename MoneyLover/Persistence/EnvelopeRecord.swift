import Foundation
import SwiftData

/// SwiftData persistence record for an `Envelope`. Allocations are in base currency (VND).
@Model
final class EnvelopeRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var allocationMinorUnits: Int
    var carriedMinorUnits: Int
    var isReserve: Bool

    init(id: UUID, name: String, iconName: String, allocationMinorUnits: Int, carriedMinorUnits: Int = 0, isReserve: Bool) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.allocationMinorUnits = allocationMinorUnits
        self.carriedMinorUnits = carriedMinorUnits
        self.isReserve = isReserve
    }
}
