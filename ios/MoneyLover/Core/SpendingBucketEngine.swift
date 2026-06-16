import Foundation

/// Aggregates Envelope spending into per-range buckets for the per-bucket chart. Pure;
/// inject the calendar and `asOf` for testability. Works in the base currency (VND).
enum SpendingBucketEngine {
    private struct Window {
        let label: String
        let start: Date
        let endExclusive: Date
    }

    /// Per-Envelope spending for `range`, or a refusal when the available history (from
    /// `earliest` to `asOf`) is shorter than the range requires.
    static func spending(
        range: ChartRange,
        envelopes: [Envelope],
        transactions: [Transaction],
        asOf: Date,
        earliest: Date?,
        calendar: Calendar = .current
    ) -> SpendingChartOutcome {
        let haveDays = earliest.map { max(0, calendar.dateComponents([.day], from: $0, to: asOf).day ?? 0) } ?? 0
        guard haveDays >= range.requiredDays else {
            return .insufficientHistory(haveDays: haveDays, needDays: range.requiredDays)
        }

        let windows = self.windows(range: range, asOf: asOf, calendar: calendar)
        let series = envelopes.map { envelope -> EnvelopeSpendSeries in
            let bars = windows.map { window -> SpendBar in
                let total = transactions
                    .filter {
                        $0.kind == .expense
                            && $0.envelopeID == envelope.id
                            && $0.date >= window.start
                            && $0.date < window.endExclusive
                    }
                    .reduce(0) { $0 + $1.amount.minorUnits }
                let span = calendar.dateComponents([.day], from: window.start, to: window.endExclusive).day ?? 1
                return SpendBar(
                    label: window.label,
                    start: window.start,
                    total: Money(minorUnits: total, currency: .vnd),
                    dayCount: max(1, span)
                )
            }
            return EnvelopeSpendSeries(id: envelope.id, name: envelope.name, bars: bars)
        }
        return .series(series)
    }

    private static func windows(range: ChartRange, asOf: Date, calendar: Calendar) -> [Window] {
        let startOfToday = calendar.startOfDay(for: asOf)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else { return [] }

        switch range {
        case .week:
            return (0..<7).reversed().compactMap { offset in
                guard let start = calendar.date(byAdding: .day, value: -offset, to: startOfToday),
                      let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
                return Window(label: weekdaySymbol(start, calendar: calendar), start: start, endExclusive: end)
            }
        case .month:
            // Four 7-day buckets ending today (28 days), labelled W1…W4 oldest-first.
            return (0..<4).map { index in
                let weeksBack = 4 - index
                let start = calendar.date(byAdding: .day, value: -7 * weeksBack, to: tomorrow)!
                let end = calendar.date(byAdding: .day, value: -7 * (weeksBack - 1), to: tomorrow)!
                return Window(label: "W\(index + 1)", start: start, endExclusive: end)
            }
        case .sixMonths:
            let comps = calendar.dateComponents([.year, .month], from: asOf)
            let currentMonthStart = calendar.date(from: comps)!
            return (0..<6).reversed().compactMap { offset in
                guard let start = calendar.date(byAdding: .month, value: -offset, to: currentMonthStart),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
                return Window(label: monthSymbol(start, calendar: calendar), start: start, endExclusive: end)
            }
        }
    }

    private static func weekdaySymbol(_ date: Date, calendar: Calendar) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        return calendar.shortWeekdaySymbols[index]
    }

    private static func monthSymbol(_ date: Date, calendar: Calendar) -> String {
        let index = calendar.component(.month, from: date) - 1
        return calendar.shortMonthSymbols[index]
    }
}
