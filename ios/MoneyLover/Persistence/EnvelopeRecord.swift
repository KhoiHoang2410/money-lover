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
    /// Optional weekly spending cap (VND minor units). Nil ⇒ no weekly cap.
    var weeklyCapMinorUnits: Int?
    /// Optional monthly spending cap (VND minor units). Nil ⇒ no monthly cap.
    var monthlyCapMinorUnits: Int?

    init(
        id: UUID,
        name: String,
        iconName: String,
        allocationMinorUnits: Int,
        carriedMinorUnits: Int = 0,
        isReserve: Bool,
        weeklyCapMinorUnits: Int? = nil,
        monthlyCapMinorUnits: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.allocationMinorUnits = allocationMinorUnits
        self.carriedMinorUnits = carriedMinorUnits
        self.isReserve = isReserve
        self.weeklyCapMinorUnits = weeklyCapMinorUnits
        self.monthlyCapMinorUnits = monthlyCapMinorUnits
    }
}
