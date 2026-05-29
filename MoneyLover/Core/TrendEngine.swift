import Foundation

/// Month-by-month trend series for the Charts screen. Pure; inject calendar and `asOf`.
/// All series cover the last `months` calendar months ending at `asOf`, oldest-first, in VND.
///
/// Rates are not historical: past net worth is valued with the *current* rate snapshot, so the
/// balance line reflects cash-flow movement, not historical FX/price swings.
enum TrendEngine {
    /// First instant of each of the last `months` months ending at `asOf`, oldest-first.
    static func monthStarts(asOf: Date, months: Int, calendar: Calendar = .current) -> [Date] {
        let comps = calendar.dateComponents([.year, .month], from: asOf)
        guard let currentStart = calendar.date(from: comps) else { return [] }
        return (0..<months).reversed().compactMap { calendar.date(byAdding: .month, value: -$0, to: currentStart) }
    }

    /// Month-end net worth (assets − debt) for each of the last `months` months.
    static func balanceTrend(
        sources: [Source],
        transactions: [Transaction],
        rates: Rates,
        asOf: Date,
        months: Int = 6,
        calendar: Calendar = .current
    ) -> [MonthPoint] {
        monthStarts(asOf: asOf, months: months, calendar: calendar).map { start in
            let cutoff = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let upto = transactions.filter { $0.date < cutoff }
            let entries = sources.map { source -> (source: Source, balance: Money) in
                let balance = (try? BalanceEngine.balance(of: source, transactions: upto)) ?? source.openingBalance
                return (source, balance)
            }
            let net = NetWorthEngine.compute(entries: entries, rates: rates).net
            return MonthPoint(date: start, value: net)
        }
    }

    /// Total expense per month for each of the last `months` months.
    static func spendingTrend(
        transactions: [Transaction],
        asOf: Date,
        months: Int = 6,
        calendar: Calendar = .current
    ) -> [MonthPoint] {
        monthStarts(asOf: asOf, months: months, calendar: calendar).map { start in
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let total = transactions
                .filter { $0.affectsBalance && $0.kind == .expense && $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.amount.minorUnits }
            return MonthPoint(date: start, value: Money(minorUnits: total, currency: .vnd))
        }
    }

    /// Cumulative contributions toward a goal at each month-end, for the last `months` months.
    static func savingTrend(
        contributions: [Contribution],
        asOf: Date,
        months: Int = 6,
        calendar: Calendar = .current
    ) -> [MonthPoint] {
        monthStarts(asOf: asOf, months: months, calendar: calendar).map { start in
            let cutoff = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let total = contributions
                .filter { $0.date < cutoff }
                .reduce(0) { $0 + $1.amount.minorUnits }
            return MonthPoint(date: start, value: Money(minorUnits: total, currency: .vnd))
        }
    }
}
