import Testing
import Foundation
@testable import MoneyLover

/// Feat — envelope weekly/monthly spending caps. The engine sums VND expenses against an envelope
/// inside the calendar week/month containing `asOf`, and flags when a set cap is reached. Pure;
/// the calendar (fixed GMT, Monday-start) and `asOf` are injected for determinism.
@Suite struct EnvelopeCapEngineTests {
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "GMT")!
        cal.firstWeekday = 2 // Monday — fixed so week boundaries don't depend on the test machine
        return cal
    }

    private let asOf = date(2026, 6, 15, hour: 12) // mid-June

    private let food = make(envelope: "Food", allocation: vnd(5_000_000))

    /// An expense inside this week and another clearly outside it (just before the week start).
    private func transactionsAcrossWeekBoundary() -> (inWeek: Date, beforeWeek: Date) {
        let week = calendar.dateInterval(of: .weekOfYear, for: asOf)!
        return (week.start, calendar.date(byAdding: .day, value: -1, to: week.start)!)
    }

    @Test func weekSpendCountsOnlyThisWeek() {
        let (inWeek, beforeWeek) = transactionsAcrossWeekBoundary()
        let txns = [
            makeExpense(vnd(120_000), source: UUID(), envelope: food.id, date: inWeek),
            makeExpense(vnd(900_000), source: UUID(), envelope: food.id, date: beforeWeek),
        ]
        let spent = EnvelopeCapEngine.spentThisWeek(envelopeID: food.id, transactions: txns, asOf: asOf, calendar: calendar)
        #expect(spent == vnd(120_000))
    }

    @Test func monthSpendCountsOnlyThisMonth() {
        let txns = [
            makeExpense(vnd(120_000), source: UUID(), envelope: food.id, date: date(2026, 6, 2)),
            makeExpense(vnd(300_000), source: UUID(), envelope: food.id, date: date(2026, 6, 28)),
            makeExpense(vnd(999_000), source: UUID(), envelope: food.id, date: date(2026, 5, 30)), // last month
        ]
        let spent = EnvelopeCapEngine.spentThisMonth(envelopeID: food.id, transactions: txns, asOf: asOf, calendar: calendar)
        #expect(spent == vnd(420_000))
    }

    @Test func ignoresOtherEnvelopesBackfillAndForeignCurrency() {
        let inWeek = calendar.dateInterval(of: .weekOfYear, for: asOf)!.start
        let txns = [
            makeExpense(vnd(100_000), source: UUID(), envelope: UUID(), date: inWeek),           // other envelope
            makeBackfill(amount: vnd(100_000), source: UUID(), envelope: food.id, date: inWeek), // informational
            makeExpense(sgd(50_00), source: UUID(), envelope: food.id, date: inWeek),            // foreign currency
            makeIncome(vnd(100_000), source: UUID(), date: inWeek),                              // not an expense
        ]
        let spent = EnvelopeCapEngine.spentThisWeek(envelopeID: food.id, transactions: txns, asOf: asOf, calendar: calendar)
        #expect(spent.isZero)
    }

    @Test func overWeeklyCapWhenSpendReachesIt() {
        let inWeek = calendar.dateInterval(of: .weekOfYear, for: asOf)!.start
        let capped = make(envelope: "Food", allocation: vnd(5_000_000))
        var withCap = capped
        withCap.weeklyCap = vnd(100_000)
        let under = [makeExpense(vnd(90_000), source: UUID(), envelope: capped.id, date: inWeek)]
        let atCap = [makeExpense(vnd(100_000), source: UUID(), envelope: capped.id, date: inWeek)]
        #expect(EnvelopeCapEngine.isOverWeeklyCap(envelope: withCap, transactions: under, asOf: asOf, calendar: calendar) == false)
        #expect(EnvelopeCapEngine.isOverWeeklyCap(envelope: withCap, transactions: atCap, asOf: asOf, calendar: calendar) == true)
    }

    @Test func noCapIsNeverOver() {
        let inWeek = calendar.dateInterval(of: .weekOfYear, for: asOf)!.start
        let txns = [makeExpense(vnd(9_000_000), source: UUID(), envelope: food.id, date: inWeek)]
        #expect(EnvelopeCapEngine.isOverWeeklyCap(envelope: food, transactions: txns, asOf: asOf, calendar: calendar) == false)
        #expect(EnvelopeCapEngine.isOverMonthlyCap(envelope: food, transactions: txns, asOf: asOf, calendar: calendar) == false)
    }
}
