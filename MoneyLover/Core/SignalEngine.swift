import Foundation

/// One goal paired with the amount actually contributed so far (computed by the caller).
struct GoalState: Sendable {
    let goal: Goal
    let actual: Money
}

/// Everything the rule engine needs to evaluate the current financial state.
struct FinanceSnapshot: Sendable {
    var envelopes: [Envelope]
    var transactions: [Transaction]
    var goals: [GoalState]
    var asOf: Date
    var calendar: Calendar

    init(envelopes: [Envelope], transactions: [Transaction], goals: [GoalState], asOf: Date, calendar: Calendar = .current) {
        self.envelopes = envelopes
        self.transactions = transactions
        self.goals = goals
        self.asOf = asOf
        self.calendar = calendar
    }
}

/// Deterministic, rule-based recommendations (ADR-0004). All thresholds are exact integer
/// comparisons on VND minor units — never floating point, never a model.
enum SignalEngine {
    /// Every Signal that fires for the snapshot, strongest first.
    static func signals(_ snapshot: FinanceSnapshot) -> [Signal] {
        let cal = snapshot.calendar
        let day = cal.component(.day, from: snapshot.asOf)
        let daysInMonth = cal.range(of: .day, in: .month, for: snapshot.asOf)?.count ?? 30

        var result: [Signal] = []

        for envelope in snapshot.envelopes {
            let spent = monthSpend(envelopeID: envelope.id, snapshot: snapshot)
            if envelope.isReserve {
                if let signal = reserveSignal(envelope, spent: spent) { result.append(signal) }
            } else if let signal = envelopeSignal(envelope, spent: spent, day: day, daysInMonth: daysInMonth) {
                result.append(signal)
            }
        }

        for state in snapshot.goals {
            if let signal = goalSignal(state, asOf: snapshot.asOf, calendar: cal) { result.append(signal) }
        }

        if let signal = largeExpenseSignal(snapshot) { result.append(signal) }

        return result.sorted { $0.severity > $1.severity }
    }

    /// An input-time nudge for charging `pending` to `envelope`, or nil if it's comfortably within plan.
    static func envelopeNudge(
        envelope: Envelope,
        transactions: [Transaction],
        adding pending: Money,
        asOf: Date,
        calendar: Calendar = .current
    ) -> Signal? {
        guard !envelope.isReserve, envelope.allocation.minorUnits > 0 else { return nil }
        let day = calendar.component(.day, from: asOf)
        let daysInMonth = calendar.range(of: .day, in: .month, for: asOf)?.count ?? 30
        let snapshot = FinanceSnapshot(envelopes: [], transactions: transactions, goals: [], asOf: asOf, calendar: calendar)
        let projected = monthSpend(envelopeID: envelope.id, snapshot: snapshot).minorUnits + max(0, pending.minorUnits)
        return envelopeSignal(envelope, spentMinor: projected, day: day, daysInMonth: daysInMonth, asNudge: true)
    }

    // MARK: - Rules

    private static func envelopeSignal(_ envelope: Envelope, spent: Money, day: Int, daysInMonth: Int) -> Signal? {
        envelopeSignal(envelope, spentMinor: spent.minorUnits, day: day, daysInMonth: daysInMonth, asNudge: false)
    }

    private static func envelopeSignal(_ envelope: Envelope, spentMinor: Int, day: Int, daysInMonth: Int, asNudge: Bool) -> Signal? {
        let allocation = envelope.allocation.minorUnits
        guard allocation > 0 else { return nil }
        let name = envelope.name

        if spentMinor > allocation {
            let over = Money(minorUnits: spentMinor - allocation, currency: .vnd)
            return Signal(
                id: "\(SignalKind.envelopeOverspent.rawValue)-\(envelope.id)",
                kind: .envelopeOverspent,
                severity: .critical,
                title: asNudge ? "This will overspend \(name)" : "\(name) is overspent",
                detail: "\(over.formatted) over the \(envelope.allocation.formatted) plan."
            )
        }

        // Linear pace: spent/elapsed > allocation  ⇔  spent·daysInMonth > allocation·day. Exact in integers.
        if day >= 1, day < daysInMonth, spentMinor * daysInMonth > allocation * day {
            return Signal(
                id: "\(SignalKind.projectedOverspend.rawValue)-\(envelope.id)",
                kind: .projectedOverspend,
                severity: .warning,
                title: asNudge ? "This will outpace \(name)" : "\(name) is on track to overspend",
                detail: "At this pace it runs out before month-end (\(Money(minorUnits: spentMinor, currency: .vnd).formatted) of \(envelope.allocation.formatted))."
            )
        }
        return nil
    }

    private static func reserveSignal(_ envelope: Envelope, spent: Money) -> Signal? {
        let remaining = envelope.allocation.minorUnits + envelope.carried.minorUnits - spent.minorUnits
        guard remaining <= 0 else { return nil }
        return Signal(
            id: "\(SignalKind.reserveLow.rawValue)-\(envelope.id)",
            kind: .reserveLow,
            severity: .critical,
            title: "Reserve is drained",
            detail: "Your \(envelope.name) buffer is down to \(Money(minorUnits: remaining, currency: .vnd).formatted)."
        )
    }

    private static func goalSignal(_ state: GoalState, asOf: Date, calendar: Calendar) -> Signal? {
        let progress = GoalTracker.progress(goal: state.goal, actual: state.actual, asOf: asOf, calendar: calendar)
        let expected = progress.expected.minorUnits
        let actual = progress.actual.minorUnits
        // Only nag past a 10% shortfall (actual < 0.9·expected ⇔ actual·10 < expected·9).
        guard expected > 0, actual * 10 < expected * 9 else { return nil }
        let shortfall = Money(minorUnits: expected - actual, currency: .vnd)
        // Critical past a 25% shortfall (actual·4 < expected·3).
        let severity: SignalSeverity = actual * 4 < expected * 3 ? .critical : .warning
        return Signal(
            id: "\(SignalKind.goalBehind.rawValue)-\(state.goal.id)",
            kind: .goalBehind,
            severity: severity,
            title: "\(state.goal.name) is behind plan",
            detail: "\(shortfall.formatted) short of where the schedule expects you."
        )
    }

    private static func largeExpenseSignal(_ snapshot: FinanceSnapshot) -> Signal? {
        let expenses = monthExpenses(snapshot)
        guard expenses.count >= 3 else { return nil }
        let sum = expenses.reduce(0) { $0 + $1.amount.minorUnits }
        guard let biggest = expenses.max(by: { $0.amount.minorUnits < $1.amount.minorUnits }) else { return nil }
        let amount = biggest.amount.minorUnits
        let others = expenses.count - 1
        // Fires when the biggest expense is more than 3× the average of the rest.
        guard amount * others > 3 * (sum - amount) else { return nil }
        let label = biggest.note.isEmpty ? "An expense" : "\"\(biggest.note)\""
        return Signal(
            id: "\(SignalKind.largeExpense.rawValue)-\(biggest.id)",
            kind: .largeExpense,
            severity: .info,
            title: "Unusually large expense",
            detail: "\(label) of \(biggest.amount.formatted) stands out this month."
        )
    }

    // MARK: - Helpers

    private static func monthExpenses(_ snapshot: FinanceSnapshot) -> [Transaction] {
        let cal = snapshot.calendar
        let target = cal.dateComponents([.year, .month], from: snapshot.asOf)
        return snapshot.transactions.filter {
            guard $0.affectsBalance, $0.kind == .expense else { return false }
            let comps = cal.dateComponents([.year, .month], from: $0.date)
            return comps.year == target.year && comps.month == target.month
        }
    }

    private static func monthSpend(envelopeID: UUID, snapshot: FinanceSnapshot) -> Money {
        let total = monthExpenses(snapshot)
            .filter { $0.envelopeID == envelopeID }
            .reduce(0) { $0 + $1.amount.minorUnits }
        return Money(minorUnits: total, currency: .vnd)
    }
}
