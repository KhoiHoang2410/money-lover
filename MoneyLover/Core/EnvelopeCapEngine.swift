import Foundation

/// Spending-cap math for Envelopes: how much was spent against an envelope in the current calendar
/// week and month, and whether that breaches an optional cap. Pure — inject the calendar and `asOf`
/// for deterministic tests. Works in the base currency (VND); foreign-currency expenses are ignored
/// (Envelopes are budgeted in VND and this engine has no rates to convert them).
enum EnvelopeCapEngine {
    /// VND spent against `envelopeID` within the calendar week containing `asOf`.
    static func spentThisWeek(
        envelopeID: UUID,
        transactions: [Transaction],
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> Money {
        spent(envelopeID: envelopeID, transactions: transactions,
              interval: calendar.dateInterval(of: .weekOfYear, for: asOf))
    }

    /// VND spent against `envelopeID` within the calendar month containing `asOf`.
    static func spentThisMonth(
        envelopeID: UUID,
        transactions: [Transaction],
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> Money {
        spent(envelopeID: envelopeID, transactions: transactions,
              interval: calendar.dateInterval(of: .month, for: asOf))
    }

    /// True when a weekly cap is set and this week's spend has reached or passed it.
    static func isOverWeeklyCap(
        envelope: Envelope,
        transactions: [Transaction],
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard let cap = envelope.weeklyCap else { return false }
        return spentThisWeek(envelopeID: envelope.id, transactions: transactions, asOf: asOf, calendar: calendar)
            .minorUnits >= cap.minorUnits
    }

    /// True when a monthly cap is set and this month's spend has reached or passed it.
    static func isOverMonthlyCap(
        envelope: Envelope,
        transactions: [Transaction],
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard let cap = envelope.monthlyCap else { return false }
        return spentThisMonth(envelopeID: envelope.id, transactions: transactions, asOf: asOf, calendar: calendar)
            .minorUnits >= cap.minorUnits
    }

    private static func spent(envelopeID: UUID, transactions: [Transaction], interval: DateInterval?) -> Money {
        guard let interval else { return .zero(.vnd) }
        let total = transactions
            .filter {
                $0.kind == .expense
                    && $0.envelopeID == envelopeID
                    && $0.amount.currency == .vnd
                    && interval.contains($0.date)
            }
            .reduce(0) { $0 + $1.amount.minorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }
}
