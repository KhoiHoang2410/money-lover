import Testing
import Foundation
@testable import MoneyLover

@Suite struct SignalEngineTests {
    private let cal = Calendar(identifier: .gregorian)
    /// 15 June 2026 — mid-month, June has 30 days (elapsed = 15/30).
    private var asOf: Date { cal.date(from: DateComponents(year: 2026, month: 6, day: 15))! }
    private func date(_ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 6, day: d))! }
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

    private func envelope(_ name: String, allocation: Int, carried: Int = 0, isReserve: Bool = false) -> Envelope {
        Envelope(name: name, iconName: "tray", allocation: vnd(allocation), carried: vnd(carried), isReserve: isReserve)
    }
    private func expense(_ amount: Int, envelopeID: UUID? = nil, day: Int = 10, note: String = "") -> Transaction {
        Transaction(date: date(day), kind: .expense, amount: vnd(amount), sourceID: UUID(), note: note, envelopeID: envelopeID)
    }
    private func snapshot(envelopes: [Envelope] = [], transactions: [Transaction] = [], goals: [GoalState] = []) -> FinanceSnapshot {
        FinanceSnapshot(envelopes: envelopes, transactions: transactions, goals: goals, asOf: asOf, calendar: cal)
    }

    // MARK: Envelope pace / overspend

    @Test func projectedOverspendFiresWhenSpendingOutpacesElapsedMonth() {
        let food = envelope("Food", allocation: 1_000_000)
        // 600k by day 15/30: 600k·30 = 18M > 1M·15 = 15M → projected to overrun.
        let signals = SignalEngine.signals(snapshot(envelopes: [food], transactions: [expense(600_000, envelopeID: food.id)]))
        #expect(signals.count == 1)
        #expect(signals[0].kind == .projectedOverspend)
        #expect(signals[0].severity == .warning)
        #expect(signals[0].id == "projectedOverspend-\(food.id)")
    }

    @Test func projectedOverspendSilentWhenOnPace() {
        let food = envelope("Food", allocation: 1_000_000)
        // 400k by day 15/30: 400k·30 = 12M < 15M → on pace.
        let signals = SignalEngine.signals(snapshot(envelopes: [food], transactions: [expense(400_000, envelopeID: food.id)]))
        #expect(signals.isEmpty)
    }

    @Test func envelopeOverspentIsCriticalWithExactOverage() {
        let food = envelope("Food", allocation: 1_000_000)
        let signals = SignalEngine.signals(snapshot(envelopes: [food], transactions: [expense(1_200_000, envelopeID: food.id)]))
        #expect(signals.count == 1)
        #expect(signals[0].kind == .envelopeOverspent)
        #expect(signals[0].severity == .critical)
        #expect(signals[0].detail.contains(vnd(200_000).formatted))
    }

    // MARK: Pace across month lengths (table-driven)

    /// Drives the engine's EXACT pace rule: with no prior overspend (spent <= allocation) the
    /// projectedOverspend warning fires iff `spent·daysInMonth > allocation·day`, i.e. the
    /// spent-fraction strictly exceeds the elapsed-fraction. Exercised across Feb (28d),
    /// Apr (30d) and May (31d) at several days-of-month.
    struct PaceCase {
        let month: Int       // 2 = Feb (28d, 2026 non-leap), 4 = Apr (30d), 5 = May (31d)
        let daysInMonth: Int // for documentation of the case
        let day: Int         // day-of-month for asOf (and expense), must be < daysInMonth
        let allocation: Int
        let spent: Int
        let shouldFire: Bool
    }

    @Test(arguments: [
        // Feb 2026 (28 days). allocation 2,800,000.
        // day 14: elapsed 14/28. spent 1,400,001·28 = 39,200,028 > 2,800,000·14 = 39,200,000 → fire.
        PaceCase(month: 2, daysInMonth: 28, day: 14, allocation: 2_800_000, spent: 1_400_001, shouldFire: true),
        // day 14: spent exactly 1,400,000 → 39,200,000 == 39,200,000, not strictly greater → silent.
        PaceCase(month: 2, daysInMonth: 28, day: 14, allocation: 2_800_000, spent: 1_400_000, shouldFire: false),
        // day 7: elapsed 7/28. spent 700,001·28 = 19,600,028 > 2,800,000·7 = 19,600,000 → fire.
        PaceCase(month: 2, daysInMonth: 28, day: 7, allocation: 2_800_000, spent: 700_001, shouldFire: true),

        // Apr 2026 (30 days). allocation 3,000,000.
        // day 10: elapsed 10/30. spent 1,000,001·30 = 30,000,030 > 3,000,000·10 = 30,000,000 → fire.
        PaceCase(month: 4, daysInMonth: 30, day: 10, allocation: 3_000_000, spent: 1_000_001, shouldFire: true),
        // day 10: spent exactly 1,000,000 → equal → silent.
        PaceCase(month: 4, daysInMonth: 30, day: 10, allocation: 3_000_000, spent: 1_000_000, shouldFire: false),
        // day 20: spent 1,900,000·30 = 57,000,000 < 3,000,000·20 = 60,000,000 → on pace, silent.
        PaceCase(month: 4, daysInMonth: 30, day: 20, allocation: 3_000_000, spent: 1_900_000, shouldFire: false),

        // May 2026 (31 days). allocation 3,100,000.
        // day 15: elapsed 15/31. spent 1,500,001·31 = 46,500,031 > 3,100,000·15 = 46,500,000 → fire.
        PaceCase(month: 5, daysInMonth: 31, day: 15, allocation: 3_100_000, spent: 1_500_001, shouldFire: true),
        // day 15: spent exactly 1,500,000 → equal → silent.
        PaceCase(month: 5, daysInMonth: 31, day: 15, allocation: 3_100_000, spent: 1_500_000, shouldFire: false),
        // day 30 (still < 31): spent 3,000,000·31 = 93,000,000 < 3,100,000·30 = 93,000,000? 93,000,000 == 93,000,000 → silent.
        PaceCase(month: 5, daysInMonth: 31, day: 30, allocation: 3_100_000, spent: 3_000_000, shouldFire: false),
    ])
    func paceThresholdFiresIffSpendFractionExceedsElapsedFraction(_ c: PaceCase) {
        let asOf = cal.date(from: DateComponents(year: 2026, month: c.month, day: c.day))!
        let food = envelope("Food", allocation: c.allocation)
        // Expense on day 1 of the same month: monthExpenses filters by year+month only.
        let firstOfMonth = cal.date(from: DateComponents(year: 2026, month: c.month, day: 1))!
        let tx = Transaction(date: firstOfMonth, kind: .expense, amount: vnd(c.spent), sourceID: UUID(), envelopeID: food.id)
        let snap = FinanceSnapshot(envelopes: [food], transactions: [tx], goals: [], asOf: asOf, calendar: cal)

        let signals = SignalEngine.signals(snap)
        let paceSignal = signals.first { $0.kind == .projectedOverspend }
        if c.shouldFire {
            #expect(paceSignal != nil)
            #expect(paceSignal?.severity == .warning)
            #expect(paceSignal?.id == "projectedOverspend-\(food.id)")
            // Never the overspent branch — spent stays within allocation in every fire case.
            #expect(!signals.contains { $0.kind == .envelopeOverspent })
        } else {
            #expect(paceSignal == nil)
        }
    }

    // MARK: Goals

    private func goal(actual: Int) -> GoalState {
        let schedule = (1...6).map { ScheduledContribution(year: 2026, month: $0, amount: vnd(1_000_000)) }
        let g = Goal(name: "House", iconName: "house", target: vnd(100_000_000), targetDate: date(28), schedule: schedule)
        return GoalState(goal: g, actual: vnd(actual))
    }

    @Test func goalBehindIsCriticalPast25Percent() {
        // expected by June = 6M; actual 3M → 50% behind → critical, 3M short.
        let signals = SignalEngine.signals(snapshot(goals: [goal(actual: 3_000_000)]))
        #expect(signals.count == 1)
        #expect(signals[0].kind == .goalBehind)
        #expect(signals[0].severity == .critical)
        #expect(signals[0].detail.contains(vnd(3_000_000).formatted))
    }

    @Test func goalBehindIsWarningBetween10And25Percent() {
        // actual 5M of 6M expected → ~17% behind → warning.
        let signals = SignalEngine.signals(snapshot(goals: [goal(actual: 5_000_000)]))
        #expect(signals.count == 1)
        #expect(signals[0].severity == .warning)
    }

    @Test func goalOnPlanIsSilent() {
        let signals = SignalEngine.signals(snapshot(goals: [goal(actual: 6_000_000)]))
        #expect(signals.isEmpty)
    }

    // MARK: Reserve

    @Test func reserveDrainedIsCritical() {
        let reserve = envelope("Reserve", allocation: 0, carried: 500_000, isReserve: true)
        let signals = SignalEngine.signals(snapshot(envelopes: [reserve], transactions: [expense(600_000, envelopeID: reserve.id)]))
        #expect(signals.count == 1)
        #expect(signals[0].kind == .reserveLow)
        #expect(signals[0].severity == .critical)
    }

    @Test func healthyReserveIsSilent() {
        let reserve = envelope("Reserve", allocation: 0, carried: 500_000, isReserve: true)
        let signals = SignalEngine.signals(snapshot(envelopes: [reserve]))
        #expect(signals.isEmpty)
    }

    // MARK: Large expense

    @Test func largeExpenseFiresAboveThreeTimesTheRest() {
        let txs = [expense(100_000), expense(100_000), expense(100_000), expense(1_000_000, note: "Flight")]
        let signals = SignalEngine.signals(snapshot(transactions: txs))
        #expect(signals.count == 1)
        #expect(signals[0].kind == .largeExpense)
        #expect(signals[0].detail.contains("Flight"))
    }

    @Test func largeExpenseSilentWhenSpendingIsEven() {
        let txs = [expense(100_000), expense(100_000), expense(120_000)]
        let signals = SignalEngine.signals(snapshot(transactions: txs))
        #expect(signals.isEmpty)
    }

    @Test func largeExpenseNeedsEnoughHistory() {
        let txs = [expense(100_000), expense(1_000_000)]
        let signals = SignalEngine.signals(snapshot(transactions: txs))
        #expect(signals.isEmpty)
    }

    // MARK: Ordering

    @Test func signalsAreSortedStrongestFirst() {
        let food = envelope("Food", allocation: 1_000_000)
        let txs = [
            expense(1_200_000, envelopeID: food.id),                              // critical overspend
            expense(100_000), expense(100_000), expense(2_000_000, note: "TV")    // info large expense
        ]
        let signals = SignalEngine.signals(snapshot(envelopes: [food], transactions: txs))
        #expect(signals.first?.severity == .critical)
        #expect(signals.last?.severity == .info)
    }

    // MARK: Input-time nudge

    @Test func nudgeWarnsWhenPendingExpenseWouldOverspend() {
        let food = envelope("Food", allocation: 1_000_000)
        let existing = [expense(800_000, envelopeID: food.id)]
        let nudge = SignalEngine.envelopeNudge(envelope: food, transactions: existing, adding: vnd(300_000), asOf: asOf, calendar: cal)
        #expect(nudge?.kind == .envelopeOverspent)
        #expect(nudge?.severity == .critical)
    }

    @Test func nudgeSilentWhenComfortablyWithinPlan() {
        let food = envelope("Food", allocation: 1_000_000)
        // day 28/30, projected 850k: 850k·30 = 25.5M < 1M·28 = 28M → on pace, within plan.
        let lateMonth = cal.date(from: DateComponents(year: 2026, month: 6, day: 28))!
        let existing = [Transaction(date: lateMonth, kind: .expense, amount: vnd(800_000), sourceID: UUID(), envelopeID: food.id)]
        let nudge = SignalEngine.envelopeNudge(envelope: food, transactions: existing, adding: vnd(50_000), asOf: lateMonth, calendar: cal)
        #expect(nudge == nil)
    }
}
