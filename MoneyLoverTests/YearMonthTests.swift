import Testing
import Foundation
@testable import MoneyLover

@Suite struct YearMonthTests {
    @Test func indexIsChronological() {
        #expect(YearMonth(year: 2026, month: 1).index < YearMonth(year: 2026, month: 2).index)
        #expect(YearMonth(year: 2026, month: 12).index + 1 == YearMonth(year: 2027, month: 1).index)
    }

    @Test func indexRoundTrips() {
        for ym in [YearMonth(year: 2026, month: 1), YearMonth(year: 2026, month: 12), YearMonth(year: 2030, month: 7)] {
            #expect(YearMonth(index: ym.index) == ym)
        }
    }

    @Test func addingRollsOverTheYear() {
        #expect(YearMonth(year: 2026, month: 11).adding(2) == YearMonth(year: 2027, month: 1))
        #expect(YearMonth(year: 2026, month: 1).adding(-1) == YearMonth(year: 2025, month: 12))
    }

    @Test func monthsThroughIsInclusive() {
        #expect(YearMonth(year: 2026, month: 1).monthsThrough(YearMonth(year: 2026, month: 1)) == 1)
        #expect(YearMonth(year: 2026, month: 1).monthsThrough(YearMonth(year: 2026, month: 8)) == 8)
        #expect(YearMonth(year: 2026, month: 1).monthsThrough(YearMonth(year: 2027, month: 1)) == 13)
    }

    @Test func monthsThroughClampsWhenReversed() {
        #expect(YearMonth(year: 2026, month: 6).monthsThrough(YearMonth(year: 2026, month: 1)) == 0)
    }

    @Test func containingExtractsYearAndMonth() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "GMT")!
        let d = cal.date(from: DateComponents(timeZone: cal.timeZone, year: 2026, month: 3, day: 17))!
        #expect(YearMonth.containing(d, calendar: cal) == YearMonth(year: 2026, month: 3))
    }

    @Test func comparableOrdersByTime() {
        #expect(YearMonth(year: 2025, month: 12) < YearMonth(year: 2026, month: 1))
    }
}
