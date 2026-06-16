import Foundation

/// The five root tabs. Bound to `TabView(selection:)` (never an Int/String).
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case overview, goals, calendar, charts, config

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .goals: "Goals"
        case .calendar: "Calendar"
        case .charts: "Charts"
        case .config: "Config"
        }
    }

    var symbol: String {
        switch self {
        case .overview: "rectangle.stack.fill"
        case .goals: "target"
        case .calendar: "calendar"
        case .charts: "chart.line.uptrend.xyaxis"
        case .config: "gearshape.fill"
        }
    }
}
