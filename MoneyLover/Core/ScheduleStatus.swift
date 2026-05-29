import Foundation

/// The funding state of a Goal's Schedule line, judged cumulatively (see ADR-0007 / CONTEXT).
enum ScheduleStatus: Sendable, Equatable {
    /// Contributions so far cover the cumulative scheduled amount through this month.
    case funded
    /// A current or future month not yet covered.
    case pending
    /// The month has passed and contributions still fall short.
    case missed
}
