import Foundation

/// A preset time window for account history. `all` means no lower bound.
enum HistoryRange: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case quarter
    case all

    var id: String { rawValue }

    /// Length of the window in days, or nil for "all time".
    var days: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .quarter: 90
        case .all: nil
        }
    }

    var label: String {
        switch self {
        case .week: "7 days"
        case .month: "30 days"
        case .quarter: "90 days"
        case .all: "All"
        }
    }
}
