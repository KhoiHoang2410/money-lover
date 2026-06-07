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
        makeStoreAndRepo(year: year, month: month, today: today).store
    }

    private func makeStoreAndRepo(year: Int, month: Int, today: Date) -> (store: CalendarStore, repo: TransactionRepository) {
        let container = try! ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repo = TransactionRepository(context: ModelContext(container))
        return (CalendarStore(repo: repo, year: year, month: month, today: today), repo)
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

    @Test func isWeekendTrueForSaturdayAndSunday() {
        // May 2026: 2nd/9th = Saturday, 3rd/10th = Sunday.
        let store = makeStore(year: 2026, month: 5, today: date(2026, 5, 31))
        #expect(store.isWeekend(2))
        #expect(store.isWeekend(3))
        #expect(store.isWeekend(9))
        #expect(store.isWeekend(10))
    }

    @Test func isWeekendFalseForWeekdays() {
        // May 2026: 1st = Friday, 4th = Monday.
        let store = makeStore(year: 2026, month: 5, today: date(2026, 5, 31))
        #expect(!store.isWeekend(1))
        #expect(!store.isWeekend(4))
    }

    // MARK: - Feat 1 & 5: add-date prefill and delete

    @Test func prefillDateUsesSelectedDay() {
        let store = makeStore(year: 2026, month: 5, today: date(2026, 5, 31))
        store.selectedDay = 12
        let comps = cal.dateComponents([.year, .month, .day], from: store.prefillDate)
        #expect(comps.year == 2026 && comps.month == 5 && comps.day == 12)
    }

    @Test func prefillDateFallsBackToTodayWhenNoDayPicked() {
        let today = date(2026, 5, 31)
        let store = makeStore(year: 2026, month: 5, today: today)
        store.selectedDay = nil
        #expect(store.prefillDate == today)
    }

    @Test func deleteRemovesTransactionFromTheDay() throws {
        let (store, repo) = makeStoreAndRepo(year: 2026, month: 5, today: date(2026, 5, 31))
        let txn = makeExpense(Money(minorUnits: 40_000, currency: .vnd), source: UUID(), date: date(2026, 5, 12), note: "Coffee")
        try repo.add(txn)
        store.load()
        store.selectedDay = 12
        #expect(store.transactions(onDay: 12).count == 1)

        store.delete(txn)
        #expect(store.transactions(onDay: 12).isEmpty)
    }
}
