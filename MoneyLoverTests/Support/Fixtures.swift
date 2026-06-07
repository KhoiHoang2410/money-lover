import Foundation
@testable import MoneyLover

// Shared test data builders. Two layers:
//   1. Named presets that mirror the DEBUG seed snapshot (`MoneyLover/Debug/SampleData.swift`)
//      with the SAME numbers, so date-independent suites can assert against a known baseline.
//   2. Parameterized `make…` builders with sane defaults + overrides for one-off cases.
// Keep all amounts in `Money` minor units — never float literals.
//
// Note on openings: the seed opens money accounts at zero and materialises each opening as an
// adjustment transaction (so the UI history is non-empty). That is a UI-history quirk, not the
// domain truth. Fixtures put the opening amount where the domain says it belongs — in
// `openingBalance` (the anchor for balance math, per CONTEXT.md → "Opening balance").

// MARK: - Money helpers

func vnd(_ minorUnits: Int) -> Money { Money(minorUnits: minorUnits, currency: .vnd) }
func sgd(_ minorUnits: Int) -> Money { Money(minorUnits: minorUnits, currency: .sgd) }
func usd(_ minorUnits: Int) -> Money { Money(minorUnits: minorUnits, currency: .usd) }

// MARK: - Date helpers (deterministic, GMT — no dependency on the test machine's calendar)

extension Calendar {
    /// A fixed Gregorian/GMT calendar so date math is identical on every machine.
    static let gmt: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "GMT")!
        return calendar
    }()
}

/// Builds a fixed `Date` for date-dependent suites. Defaults to the 1st at midnight GMT.
func date(_ year: Int, _ month: Int, _ day: Int = 1, hour: Int = 0, minute: Int = 0) -> Date {
    Calendar.gmt.date(
        from: DateComponents(
            timeZone: TimeZone(identifier: "GMT"),
            year: year, month: month, day: day, hour: hour, minute: minute
        )
    )!
}

/// A frozen "now" for suites that need a stable as-of date. The seed schedules run across 2026,
/// so mid-year is a useful default (some lines past, some future).
let anchor2026 = date(2026, 6, 1)

// MARK: - Parameterized builders (defaults + overrides)

/// Generic source builder. Opening defaults to zero in the chosen currency.
func makeSource(
    name: String = "Test Account",
    kind: SourceKind = .account,
    currency: Currency = .vnd,
    opening: Money? = nil,
    iconName: String = "banknote.fill",
    logoAsset: String? = nil,
    holding: HoldingInfo? = nil
) -> Source {
    Source(
        name: name,
        kind: kind,
        currency: currency,
        openingBalance: opening ?? .zero(currency),
        iconName: iconName,
        logoAsset: logoAsset,
        holding: holding
    )
}

/// Envelope builder. Matches the `make(envelope:)` name used in the testing guidelines.
func make(
    envelope name: String,
    allocation: Money,
    carried: Money = .zero(.vnd),
    isReserve: Bool = false,
    iconName: String = "tray.fill"
) -> Envelope {
    Envelope(name: name, iconName: iconName, allocation: allocation, carried: carried, isReserve: isReserve)
}

/// One scheduled-contribution line (VND).
func sched(_ year: Int, _ month: Int, _ amount: Money) -> ScheduledContribution {
    ScheduledContribution(year: year, month: month, amount: amount)
}

/// Goal builder.
func makeGoal(
    name: String = "Goal",
    iconName: String = "target",
    target: Money,
    targetDate: Date,
    schedule: [ScheduledContribution] = []
) -> Goal {
    Goal(name: name, iconName: iconName, target: target, targetDate: targetDate, schedule: schedule)
}

/// Generic transaction builder — every kind flows through here.
func makeTransaction(
    _ kind: TransactionKind,
    amount: Money,
    sourceID: UUID,
    date txnDate: Date = anchor2026,
    destinationID: UUID? = nil,
    destinationAmount: Money? = nil,
    fee: Money? = nil,
    note: String = "",
    envelopeID: UUID? = nil,
    goalID: UUID? = nil
) -> Transaction {
    Transaction(
        date: txnDate,
        kind: kind,
        amount: amount,
        sourceID: sourceID,
        destinationID: destinationID,
        destinationAmount: destinationAmount,
        fee: fee,
        note: note,
        envelopeID: envelopeID,
        goalID: goalID
    )
}

func makeExpense(_ amount: Money, source: UUID, envelope: UUID? = nil, date txnDate: Date = anchor2026, note: String = "Expense") -> Transaction {
    makeTransaction(.expense, amount: amount, sourceID: source, date: txnDate, note: note, envelopeID: envelope)
}

func makeIncome(_ amount: Money, source: UUID, date txnDate: Date = anchor2026, note: String = "Income") -> Transaction {
    makeTransaction(.income, amount: amount, sourceID: source, date: txnDate, note: note)
}

/// Same-currency transfer (e.g. paying a credit-card bill: Account ↓, Liability ↓).
func makeTransfer(_ amount: Money, from: UUID, to: UUID, date txnDate: Date = anchor2026, note: String = "Transfer") -> Transaction {
    makeTransaction(.transfer, amount: amount, sourceID: from, date: txnDate, destinationID: to, note: note)
}

/// Cross-currency transfer (e.g. Wise SGD → VPBank VND): records amount out, amount in, and the Fee.
func makeCrossCurrencyTransfer(
    out amount: Money,
    from: UUID,
    to: UUID,
    received destinationAmount: Money,
    fee: Money,
    date txnDate: Date = anchor2026,
    note: String = "FX transfer"
) -> Transaction {
    makeTransaction(.transfer, amount: amount, sourceID: from, date: txnDate, destinationID: to, destinationAmount: destinationAmount, fee: fee, note: note)
}

/// A Contribution: a `.transfer` from a VND Account into a Goal (ADR-0007) — `goalID` set, no destination Source.
func makeContribution(_ amount: Money, from account: UUID, goal goalID: UUID, date txnDate: Date = anchor2026, note: String = "→ Goal") -> Transaction {
    makeTransaction(.transfer, amount: amount, sourceID: account, date: txnDate, note: note, goalID: goalID)
}

/// Reconcile Adjustment — signed amount absorbing a balance difference; carries a description + envelope.
func makeAdjustment(_ amount: Money, source: UUID, envelope: UUID? = nil, date txnDate: Date = anchor2026, note: String = "Adjustment") -> Transaction {
    makeTransaction(.adjustment, amount: amount, sourceID: source, date: txnDate, note: note, envelopeID: envelope)
}

/// An Invest (Buy/Sell of a Holding, ADR-0010): VND `account` (sourceID) trades `quantity` units of
/// `holding` (destinationID) at `unitPrice`; `amount` = quantity × unitPrice in VND.
func makeInvest(
    _ direction: TradeDirection,
    quantity: Decimal,
    unitPrice: Money,
    account: UUID,
    holding: UUID,
    date txnDate: Date = anchor2026
) -> Transaction {
    Transaction(
        date: txnDate,
        kind: .invest,
        amount: Money(major: quantity * unitPrice.amount, currency: .vnd),
        sourceID: account,
        destinationID: holding,
        note: "\(direction.title) holding",
        tradeQuantity: quantity,
        tradeDirection: direction
    )
}

// MARK: - Named presets (mirror the seed snapshot, exact numbers)

enum Fixtures {

    // Presets are stored `static let` (not computed `var`) so each has a STABLE identity within a
    // run — `Fixtures.travelGoal.id` is the same UUID on every access, letting tests wire
    // relationships (a transaction's sourceID/envelopeID/goalID pointing at a preset).

    // Sources — accounts. Openings are the seed's effective balances (see file header note).
    static let mbBank = makeSource(name: "MBBank", currency: .vnd, opening: vnd(80_000_000), logoAsset: "mbbank")
    static let vpBank = makeSource(name: "VPBank", currency: .vnd, opening: vnd(12_500_000), logoAsset: "vpbank")
    static let vib = makeSource(name: "VIB", currency: .vnd, opening: vnd(3_200_000), logoAsset: "vib")
    static let wiseSGD = makeSource(name: "Wise SGD", currency: .sgd, opening: sgd(2_400_00), iconName: "globe", logoAsset: "wise")
    static let wiseUSD = makeSource(name: "Wise USD", currency: .usd, opening: usd(1_100_00), iconName: "globe", logoAsset: "wise")
    static let cash = makeSource(name: "Cash", currency: .vnd, opening: vnd(1_500_000), iconName: "wallet.bifold.fill")
    static let savings = makeSource(name: "Savings", currency: .vnd, opening: vnd(520_000_000))

    // Sources — holdings (value = quantity × rate; opening stays zero).
    static let goldSJC = makeSource(name: "Gold SJC", kind: .holding, currency: .vnd, iconName: "seal.fill", holding: HoldingInfo(quantity: 5, unit: .chi))
    static let fptStock = makeSource(name: "FPT", kind: .holding, currency: .vnd, iconName: "chart.line.uptrend.xyaxis", holding: HoldingInfo(quantity: 500, unit: .shares, ticker: "FPT"))

    // Sources — credit cards (Liabilities; open negative = debt).
    static let vpCredit = makeSource(name: "VPBank Credit", kind: .creditCard, currency: .vnd, opening: vnd(-18_300_000), iconName: "creditcard.fill")
    static let mbCredit = makeSource(name: "MBBank Credit", kind: .creditCard, currency: .vnd, opening: vnd(-4_000_000), iconName: "creditcard.fill")

    /// All eleven seed sources.
    static let allSources: [Source] = [mbBank, vpBank, vib, wiseSGD, wiseUSD, cash, savings, goldSJC, fptStock, vpCredit, mbCredit]

    // Envelopes (+ Reserve).
    static let food = make(envelope: "Food", allocation: vnd(5_000_000), iconName: "fork.knife")
    static let rent = make(envelope: "Rent", allocation: vnd(8_000_000), iconName: "house.fill")
    static let transport = make(envelope: "Transport", allocation: vnd(2_000_000), iconName: "car.fill")
    static let fun = make(envelope: "Fun", allocation: vnd(7_000_000), iconName: "sparkles")
    static let reserve = make(envelope: "Reserve", allocation: .zero(.vnd), carried: vnd(23_000_000), isReserve: true, iconName: "star.fill")

    /// The default Envelope set = the Allocation template (CONTEXT.md → "Allocation template").
    /// There is no separate `AllocationTemplate` domain type; the template *is* this set of Envelopes.
    static let allocationTemplate: [Envelope] = [food, rent, transport, fun, reserve]

    // Rates (matches the seed's offline rate set).
    static let standardRates = Rates(fx: [.vnd: 1, .usd: 25_500, .sgd: 18_500], goldPerChi: 15_950_000, stock: ["FPT": 72_000])

    // Goals — non-flat schedules with gap months, exactly like the seed.
    /// House: Jan–Mar 100M, May 150M, Jul–Sep 100M (note the Apr and Jun gaps).
    static let houseGoal = makeGoal(
        name: "House", iconName: "house.fill", target: vnd(3_000_000_000), targetDate: date(2027, 6, 1),
        schedule: [
            sched(2026, 1, vnd(100_000_000)), sched(2026, 2, vnd(100_000_000)), sched(2026, 3, vnd(100_000_000)),
            sched(2026, 5, vnd(150_000_000)),
            sched(2026, 7, vnd(100_000_000)), sched(2026, 8, vnd(100_000_000)), sched(2026, 9, vnd(100_000_000)),
        ]
    )
    /// Car: a flat 25M every month, Jan–Dec.
    static let carGoal = makeGoal(
        name: "Car", iconName: "car.fill", target: vnd(600_000_000), targetDate: date(2027, 6, 1),
        schedule: (1...12).map { sched(2026, $0, vnd(25_000_000)) }
    )
    /// Travel: 10M a month, Jan–Aug.
    static let travelGoal = makeGoal(
        name: "Travel", iconName: "airplane", target: vnd(80_000_000), targetDate: date(2026, 12, 1),
        schedule: (1...8).map { sched(2026, $0, vnd(10_000_000)) }
    )

    static let allGoals: [Goal] = [houseGoal, carGoal, travelGoal]
}
