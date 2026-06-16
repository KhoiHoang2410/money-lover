import Foundation

/// The funding state of a Goal's Schedule line, judged cumulatively (see ADR-0007 / CONTEXT).
enum ScheduleStatus: Sendable, Equatable {
    /// Contributions so far cover the cumulative scheduled amount through this month.
    case funded
    /// The *current* month's cumulative amount is not yet met (still fundable this month).
    case due
    /// A future month not yet covered.
    case pending
    /// A *past* month whose cumulative amount was never met.
    case missed
}
