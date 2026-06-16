import Foundation

/// One bar in a per-Envelope spending series: the spend over a sub-period, plus the
/// average-per-day scaling that makes bars comparable across ranges.
struct SpendBar: Identifiable, Hashable, Sendable {
    /// Short axis label, e.g. a weekday ("Mon"), a week ("W1"), or a month ("Jan").
    let label: String
    /// First instant of the bucket — stable identity and x-ordering.
    let start: Date
    /// Total spent in this bucket, VND.
    let total: Money
    /// Number of days the bucket spans (≥ 1).
    let dayCount: Int

    var id: Date { start }

    /// Bucket total ÷ day count, VND. For a 1-day bucket this equals `total`.
    var averagePerDay: Money {
        Money(minorUnits: dayCount == 0 ? 0 : total.minorUnits / dayCount, currency: total.currency)
    }
}

/// One Envelope's spending bars across the chosen range.
struct EnvelopeSpendSeries: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let bars: [SpendBar]
}

/// Result of aggregating per-Envelope spending: either the series, or an explicit refusal
/// when history is too short to be meaningful for the chosen range.
enum SpendingChartOutcome: Hashable, Sendable {
    case series([EnvelopeSpendSeries])
    case insufficientHistory(haveDays: Int, needDays: Int)
}
