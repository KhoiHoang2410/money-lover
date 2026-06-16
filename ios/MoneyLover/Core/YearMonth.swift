import Foundation

/// A calendar month (`year` + `month` in 1...12) — the unit a Goal's funding window and its
/// Schedule are expressed in. Contributions to a Goal happen monthly, so a Goal is bounded by a
/// **start month** and an **end month**, not an exact day. Comparable in chronological order.
struct YearMonth: Hashable, Sendable, Codable, Comparable {
    var year: Int
    var month: Int   // 1...12

    init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    /// `year * 12 + (month - 1)` — a chronological key for comparison and month arithmetic.
    var index: Int { year * 12 + (month - 1) }

    /// Reconstructs a month from its `index` (the inverse of `index`).
    init(index: Int) {
        self.year = index / 12
        self.month = index % 12 + 1
    }

    /// The calendar month containing `date`.
    static func containing(_ date: Date, calendar: Calendar = .current) -> YearMonth {
        let c = calendar.dateComponents([.year, .month], from: date)
        return YearMonth(year: c.year ?? 0, month: c.month ?? 1)
    }

    /// This month shifted by `months` (may be negative).
    func adding(_ months: Int) -> YearMonth {
        YearMonth(index: index + months)
    }

    /// Inclusive count of months from `self` through `other` (1 for the same month). Clamped to ≥ 0
    /// when `other` precedes `self`.
    func monthsThrough(_ other: YearMonth) -> Int {
        max(0, other.index - index + 1)
    }

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool { lhs.index < rhs.index }
}
