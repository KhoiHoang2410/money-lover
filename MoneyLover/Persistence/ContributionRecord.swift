import Foundation
import SwiftData

/// A contribution actually made toward a Goal (base currency VND).
@Model
final class ContributionRecord {
    @Attribute(.unique) var id: UUID
    var goalID: UUID
    var date: Date
    var amountMinorUnits: Int

    init(id: UUID, goalID: UUID, date: Date, amountMinorUnits: Int) {
        self.id = id
        self.goalID = goalID
        self.date = date
        self.amountMinorUnits = amountMinorUnits
    }
}
