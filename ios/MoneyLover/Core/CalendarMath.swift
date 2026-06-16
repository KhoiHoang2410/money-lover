import Foundation

/// Per-day cash-flow math for the Calendar. Pure; inject the calendar for testability.
enum CalendarMath {
    /// Net (+income, −expense, ±adjustment) per day-of-month for the given month, in VND.
    /// Transfers are internal and excluded. Backfilled entries are ordinary transactions and count
    /// like any other (they appear on their past date). Foreign-currency entries are excluded
    /// rather than summed at face value — the grid is a VND cash-flow view and carries no rates.
    static func dailyNet(transactions: [Transaction], year: Int, month: Int, calendar: Calendar = .current) -> [Int: Money] {
        var totals: [Int: Int] = [:]
        for transaction in transactions where transaction.amount.currency == .vnd {
            let comps = calendar.dateComponents([.year, .month, .day], from: transaction.date)
            guard comps.year == year, comps.month == month, let day = comps.day else { continue }
            switch transaction.kind {
            case .expense: totals[day, default: 0] -= transaction.amount.minorUnits
            case .income: totals[day, default: 0] += transaction.amount.minorUnits
            case .adjustment: totals[day, default: 0] += transaction.amount.minorUnits
            // Transfers and Invests are internal moves (own place ↔ holding) — not cash flow.
            case .transfer, .invest: continue
            }
        }
        return totals.mapValues { Money(minorUnits: $0, currency: .vnd) }
    }
}
