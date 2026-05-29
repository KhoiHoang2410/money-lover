import Foundation

/// One month's value on a trend line (balance, spending, or cumulative saving). VND.
struct MonthPoint: Identifiable, Hashable, Sendable {
    /// First instant of the month — the x-position on a `.month` time axis.
    let date: Date
    let value: Money

    var id: Date { date }
}
