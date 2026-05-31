import Testing
import Foundation
import SwiftData
@testable import MoneyLover

@MainActor
@Suite struct CalendarStoreTests {
    private let cal = Calendar(identifier: .gregorian)

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func makeStore(year: Int, month: Int, today: Date) -> CalendarStore {
        let container = try! ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repo = TransactionRepository(context: ModelContext(container))
        return CalendarStore(repo: repo, year: year, month: month, today: today)
    }

    @Test func isTodayMatchesOnlyInjectedDay() {
        let store = makeStore(year: 2026, month: 5, today: date(2026, 5, 31))
        #expect(store.isToday(31))
        #expect(!store.isToday(30))
    }

    @Test func isTodayFalseWhenViewingAnotherMonth() {
        let store = makeStore(year: 2026, month: 4, today: date(2026, 5, 31))
        #expect(!store.isToday(31))
    }

    @Test func jumpToTodayMovesToCurrentMonthAndSelectsToday() {
        let store = makeStore(year: 2026, month: 1, today: date(2026, 5, 31))
        store.jumpToToday()
        #expect(store.year == 2026)
        #expect(store.month == 5)
        #expect(store.selectedDay == 31)
    }

    @Test func jumpToTodaySelectsTodayEvenWhenAlreadyOnCurrentMonth() {
        let store = makeStore(year: 2026, month: 5, today: date(2026, 5, 31))
        store.selectedDay = nil
        store.jumpToToday()
        #expect(store.selectedDay == 31)
    }
}
