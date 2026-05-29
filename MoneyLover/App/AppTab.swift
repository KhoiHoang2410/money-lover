import Foundation

/// The five root tabs. Bound to `TabView(selection:)` (never an Int/String).
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case overview, goals, calendar, input, config

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .goals: "Goals"
        case .calendar: "Calendar"
        case .input: "Add"
        case .config: "Config"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "rectangle.stack.fill"
        case .goals: "target"
        case .calendar: "calendar"
        case .input: "plus"
        case .config: "gearshape.fill"
        }
    }
}
