import Testing
import Foundation
@testable import MoneyLover

@Suite struct TrendEngineTests {
    private let cal = Calendar(identifier: .gregorian)
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

    @Test func monthStartsAreOldestFirstAndSpanRequestedMonths() {
        let starts = TrendEngine.monthStarts(asOf: date(2026, 5, 29), months: 6, calendar: cal)
        #expect(starts.count == 6)
        #expect(cal.dateComponents([.year, .month], from: starts.first!).month == 12)  // Dec 2025
        #expect(cal.dateComponents([.year, .month], from: starts.last!).month == 5)     // May 2026
    }

    @Test func spendingTrendSumsExpensesPerMonth() {
        let txs = [
            Transaction(date: date(2026, 4, 10), kind: .expense, amount: vnd(120_000), sourceID: UUID()),
            Transaction(date: date(2026, 4, 20), kind: .expense, amount: vnd(80_000), sourceID: UUID()),
            Transaction(date: date(2026, 5, 2), kind: .expense, amount: vnd(50_000), sourceID: UUID()),
            Transaction(date: date(2026, 5, 2), kind: .income, amount: vnd(9_000_000), sourceID: UUID())
        ]
        let points = TrendEngine.spendingTrend(transactions: txs, asOf: date(2026, 5, 29), months: 6, calendar: cal)
        #expect(points.count == 6)
        #expect(points[4].value == vnd(200_000))  // April
        #expect(points[5].value == vnd(50_000))   // May (income excluded)
    }

    @Test func savingTrendIsCumulativeAcrossMonths() {
        let goalID = UUID()
        let contributions = [
            Contribution(goalID: goalID, date: date(2026, 3, 5), amount: vnd(1_000_000)),
            Contribution(goalID: goalID, date: date(2026, 4, 5), amount: vnd(2_000_000)),
            Contribution(goalID: goalID, date: date(2026, 5, 5), amount: vnd(500_000))
        ]
        let points = TrendEngine.savingTrend(contributions: contributions, asOf: date(2026, 5, 29), months: 6, calendar: cal)
        #expect(points[4].value == vnd(3_000_000))  // through April: 1M + 2M
        #expect(points[5].value == vnd(3_500_000))  // through May: + 0.5M
    }

    @Test func balanceTrendReplaysTransactionsUpToEachMonthEnd() {
        let source = Source(name: "Cash", kind: .account, currency: .vnd, openingBalance: vnd(1_000_000), iconName: "cash")
        let txs = [
            Transaction(date: date(2026, 4, 15), kind: .income, amount: vnd(500_000), sourceID: source.id),
            Transaction(date: date(2026, 5, 15), kind: .expense, amount: vnd(200_000), sourceID: source.id)
        ]
        let rates = Rates(fx: [.vnd: 1], goldPerChi: 0, stock: [:])
        let points = TrendEngine.balanceTrend(
            sources: [source], transactions: txs, rates: rates,
            asOf: date(2026, 5, 29), months: 6, calendar: cal
        )
        #expect(points[4].value == vnd(1_500_000))  // end of April: opening + income
        #expect(points[5].value == vnd(1_300_000))  // end of May: − expense
    }
}
