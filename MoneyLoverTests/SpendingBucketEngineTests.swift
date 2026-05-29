import Testing
import Foundation
@testable import MoneyLover

@Suite struct SpendingBucketEngineTests {
    private let cal = Calendar(identifier: .gregorian)
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

    private let envID = UUID()
    private func food() -> Envelope { Envelope(id: envID, name: "Food", iconName: "food", allocation: vnd(3_000_000)) }
    private func expense(_ y: Int, _ m: Int, _ d: Int, _ amount: Int) -> Transaction {
        Transaction(date: date(y, m, d), kind: .expense, amount: vnd(amount), sourceID: UUID(), envelopeID: envID)
    }

    @Test func weekHasSevenDailyBarsWithAveragePerDayEqualToTotal() {
        let asOf = date(2026, 5, 29)
        let txs = [expense(2026, 5, 29, 100_000), expense(2026, 5, 28, 40_000), expense(2026, 5, 28, 10_000)]
        let outcome = SpendingBucketEngine.spending(
            range: .week, envelopes: [food()], transactions: txs,
            asOf: asOf, earliest: date(2026, 1, 1), calendar: cal
        )
        guard case let .series(series) = outcome, let bars = series.first?.bars else {
            Issue.record("expected series"); return
        }
        #expect(bars.count == 7)
        #expect(bars.allSatisfy { $0.dayCount == 1 })
        #expect(bars.last?.total == vnd(100_000))             // 29th
        #expect(bars[5].total == vnd(50_000))                 // 28th
        // 1-day bucket: averagePerDay equals the day's total.
        #expect(bars.last?.averagePerDay == vnd(100_000))
    }

    @Test func sixMonthsBucketsByCalendarMonthAndScalesToAveragePerDay() {
        let asOf = date(2026, 5, 29)
        // 310,000 spent across May (31 days) ⇒ avg/day = 10,000.
        let txs = [expense(2026, 5, 5, 200_000), expense(2026, 5, 20, 110_000)]
        let outcome = SpendingBucketEngine.spending(
            range: .sixMonths, envelopes: [food()], transactions: txs,
            asOf: asOf, earliest: date(2025, 1, 1), calendar: cal
        )
        guard case let .series(series) = outcome, let bars = series.first?.bars else {
            Issue.record("expected series"); return
        }
        #expect(bars.count == 6)
        let may = bars.last!
        #expect(may.total == vnd(310_000))
        #expect(may.dayCount == 31)
        #expect(may.averagePerDay == vnd(10_000))
    }

    @Test func refusesWhenHistoryShorterThanRange() {
        let asOf = date(2026, 5, 29)
        let outcome = SpendingBucketEngine.spending(
            range: .sixMonths, envelopes: [food()], transactions: [expense(2026, 5, 1, 50_000)],
            asOf: asOf, earliest: date(2026, 3, 1), calendar: cal     // ~89 days < 180
        )
        guard case let .insufficientHistory(have, need) = outcome else {
            Issue.record("expected refusal"); return
        }
        #expect(need == 180)
        #expect(have < need)
    }

    @Test func refusesWhenNoHistoryAtAll() {
        let outcome = SpendingBucketEngine.spending(
            range: .week, envelopes: [food()], transactions: [],
            asOf: date(2026, 5, 29), earliest: nil, calendar: cal
        )
        #expect(outcome == .insufficientHistory(haveDays: 0, needDays: 7))
    }

    @Test func excludesOtherEnvelopesAndInformationalEntries() {
        let asOf = date(2026, 5, 29)
        let other = Transaction(date: date(2026, 5, 28), kind: .expense, amount: vnd(999_000), sourceID: UUID(), envelopeID: UUID())
        let backfill = Transaction(date: date(2026, 5, 28), kind: .expense, amount: vnd(500_000), sourceID: UUID(), envelopeID: envID, affectsBalance: false)
        let outcome = SpendingBucketEngine.spending(
            range: .week, envelopes: [food()], transactions: [other, backfill, expense(2026, 5, 28, 30_000)],
            asOf: asOf, earliest: date(2026, 1, 1), calendar: cal
        )
        guard case let .series(series) = outcome else { Issue.record("expected series"); return }
        let total = series[0].bars.reduce(0) { $0 + $1.total.minorUnits }
        #expect(total == 30_000)
    }
}
