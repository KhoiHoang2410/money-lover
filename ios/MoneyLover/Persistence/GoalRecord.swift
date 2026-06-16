import Foundation
import SwiftData

/// SwiftData record for a `Goal`. The schedule is stored as JSON.
@Model
final class GoalRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var targetMinorUnits: Int
    /// Funding window stored as chronological month indices (`YearMonth.index`).
    var startMonthIndex: Int
    var endMonthIndex: Int
    var scheduleData: Data

    init(id: UUID, name: String, iconName: String, targetMinorUnits: Int, startMonthIndex: Int, endMonthIndex: Int, scheduleData: Data) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.targetMinorUnits = targetMinorUnits
        self.startMonthIndex = startMonthIndex
        self.endMonthIndex = endMonthIndex
        self.scheduleData = scheduleData
    }
}
