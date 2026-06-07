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

    @Test func emitsIndependentSeriesPerEnvelopeSoEachRowScalesToItsOwnMax() {
        // TC-18-04: two Envelopes with very different spend totals over the same range.
        // The engine emits one series per Envelope, each with its own bars/totals, so the
        // view can scale each row to its own max.
        let asOf = date(2026, 5, 29)
        let transportID = UUID()
        let transport = Envelope(id: transportID, name: "Transport", iconName: "car", allocation: vnd(2_000_000))
        let transportExpense = { (y: Int, m: Int, d: Int, amount: Int) in
            Transaction(date: self.date(y, m, d), kind: .expense, amount: self.vnd(amount), sourceID: UUID(), envelopeID: transportID)
        }
        let txs = [
            expense(2026, 5, 28, 50_000),                 // Food on the 28th
            transportExpense(2026, 5, 28, 500_000)        // Transport on the 28th (10×)
        ]
        let outcome = SpendingBucketEngine.spending(
            range: .week, envelopes: [food(), transport], transactions: txs,
            asOf: asOf, earliest: date(2026, 1, 1), calendar: cal
        )
        guard case let .series(series) = outcome else { Issue.record("expected series"); return }
        #expect(series.count == 2)

        let foodSeries = series.first { $0.id == envID }!
        let transportSeries = series.first { $0.id == transportID }!

        // Each series tops out at its own Envelope's spend — independent maxima.
        let foodMax = foodSeries.bars.map(\.total.minorUnits).max()!
        let transportMax = transportSeries.bars.map(\.total.minorUnits).max()!
        #expect(foodMax == 50_000)
        #expect(transportMax == 500_000)
        #expect(foodMax != transportMax)

        // The series carry only their own Envelope's spend (no cross-contamination).
        #expect(foodSeries.bars.reduce(0) { $0 + $1.total.minorUnits } == 50_000)
        #expect(transportSeries.bars.reduce(0) { $0 + $1.total.minorUnits } == 500_000)
    }

    @Test func excludesOtherEnvelopes() {
        let asOf = date(2026, 5, 29)
        let other = Transaction(date: date(2026, 5, 28), kind: .expense, amount: vnd(999_000), sourceID: UUID(), envelopeID: UUID())
        let outcome = SpendingBucketEngine.spending(
            range: .week, envelopes: [food()], transactions: [other, expense(2026, 5, 28, 30_000)],
            asOf: asOf, earliest: date(2026, 1, 1), calendar: cal
        )
        guard case let .series(series) = outcome else { Issue.record("expected series"); return }
        let total = series[0].bars.reduce(0) { $0 + $1.total.minorUnits }
        #expect(total == 30_000)
    }
}
