import Foundation

/// Window for the per-Envelope spending chart. 7 days shows raw daily bars; 30 days and
/// 6 months bucket into sub-periods whose bars are scaled to an average-per-day value so the
/// y-axis is comparable across ranges.
enum ChartRange: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case sixMonths

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "Last 7 days"
        case .month: "Last 30 days"
        case .sixMonths: "Last 6 months"
        }
    }

    /// Days of history the chart needs before it will draw; otherwise it refuses.
    var requiredDays: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .sixMonths: 180
        }
    }

    /// Whether bars are scaled to average-per-day (true for everything but the daily 7-day view).
    var usesAveragePerDay: Bool { self != .week }
}
