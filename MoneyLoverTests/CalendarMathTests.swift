import Testing
import Foundation
@testable import MoneyLover

@Suite struct CalendarMathTests {
    private let cal = Calendar(identifier: .gregorian)
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

    @Test func netsExpenseAndIncomePerDay() {
        let txs = [
            Transaction(date: date(2026,5,5), kind: .expense, amount: vnd(120_000), sourceID: UUID()),
            Transaction(date: date(2026,5,5), kind: .expense, amount: vnd(60_000), sourceID: UUID()),
            Transaction(date: date(2026,5,25), kind: .income, amount: vnd(80_000_000), sourceID: UUID())
        ]
        let net = CalendarMath.dailyNet(transactions: txs, year: 2026, month: 5, calendar: cal)
        #expect(net[5] == vnd(-180_000))
        #expect(net[25] == vnd(80_000_000))
    }

    @Test func includesBackfilledEntries() {
        // A Backfill is an ordinary transaction (ADR-0012): it lands on its past date and counts in
        // the day's net like any other expense.
        let txs = [
            Transaction(date: date(2026,5,12), kind: .expense, amount: vnd(200_000), sourceID: UUID()),
            Transaction(date: date(2026,5,12), kind: .expense, amount: vnd(500_000), sourceID: UUID())
        ]
        let net = CalendarMath.dailyNet(transactions: txs, year: 2026, month: 5, calendar: cal)
        #expect(net[12] == vnd(-700_000))
    }

    @Test func excludesForeignCurrencyEntries() {
        // The grid is a VND cash-flow view and carries no rates, so a non-VND entry is
        // excluded rather than summed at face value.
        let txs = [
            Transaction(date: date(2026,5,15), kind: .expense, amount: Money(minorUnits: 100_00, currency: .usd), sourceID: UUID()),
            Transaction(date: date(2026,5,15), kind: .expense, amount: vnd(70_000), sourceID: UUID())
        ]
        let net = CalendarMath.dailyNet(transactions: txs, year: 2026, month: 5, calendar: cal)
        #expect(net[15] == vnd(-70_000))
    }

    @Test func excludesTransfersAndOtherMonths() {
        let txs = [
            Transaction(date: date(2026,5,10), kind: .transfer, amount: vnd(5_000_000), sourceID: UUID(), destinationID: UUID()),
            Transaction(date: date(2026,4,10), kind: .expense, amount: vnd(999_000), sourceID: UUID())
        ]
        let net = CalendarMath.dailyNet(transactions: txs, year: 2026, month: 5, calendar: cal)
        #expect(net.isEmpty)
    }
}
