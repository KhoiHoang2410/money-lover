import Foundation
import SwiftData

/// SwiftData record for a `Goal`. The schedule is stored as JSON.
@Model
final class GoalRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var targetMinorUnits: Int
    var targetDate: Date
    var scheduleData: Data

    init(id: UUID, name: String, iconName: String, targetMinorUnits: Int, targetDate: Date, scheduleData: Data) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.targetMinorUnits = targetMinorUnits
        self.targetDate = targetDate
        self.scheduleData = scheduleData
    }
}
