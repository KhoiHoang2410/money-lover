import Foundation

/// A deterministic spending insight produced by `SignalEngine`. The numbers are computed in
/// Swift (ADR-0004); a model may only rephrase `title`/`detail`, never decide whether a Signal fires.
struct Signal: Identifiable, Equatable, Sendable {
    /// Stable across recomputations for the same underlying entity, so views can diff cleanly.
    let id: String
    let kind: SignalKind
    let severity: SignalSeverity
    let title: String
    let detail: String
}

enum SignalSeverity: Int, Sendable, Comparable {
    case info, warning, critical

    static func < (lhs: SignalSeverity, rhs: SignalSeverity) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum SignalKind: String, Sendable {
    case projectedOverspend
    case envelopeOverspent
    case goalBehind
    case reserveLow
    case largeExpense

    var iconName: String {
        switch self {
        case .projectedOverspend: "gauge.with.dots.needle.67percent"
        case .envelopeOverspent: "exclamationmark.triangle.fill"
        case .goalBehind: "flag.slash.fill"
        case .reserveLow: "tray.and.arrow.down.fill"
        case .largeExpense: "arrow.up.right.circle.fill"
        }
    }
}
