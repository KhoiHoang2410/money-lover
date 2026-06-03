import Foundation
import Observation

/// View state for the Calendar: transactions and the displayed month.
@MainActor
@Observable
final class CalendarStore {
    private let repo: TransactionRepository
    private let calendar = Calendar.current
    /// Injected "now" so today-detection stays deterministic in tests.
    private let today: Date
    private(set) var transactions: [Transaction] = []
    var year: Int { didSet { selectedDay = nil } }
    var month: Int { didSet { selectedDay = nil } }
    /// The day whose detail is shown inline below the grid; nil means none picked.
    var selectedDay: Int?
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(repo: TransactionRepository, year: Int, month: Int, today: Date = .now) {
        self.repo = repo
        self.year = year
        self.month = month
        self.today = today
        changeObserver.observe { [weak self] in self?.load() }
    }

    /// True when `day` in the displayed month/year is the real-world current date.
    func isToday(_ day: Int) -> Bool {
        let c = calendar.dateComponents([.year, .month, .day], from: today)
        return c.year == year && c.month == month && c.day == day
    }

    /// Jump the grid to the current month/year and select today.
    /// Setting month/year clears `selectedDay` (didSet), so select today afterwards.
    func jumpToToday() {
        let c = calendar.dateComponents([.year, .month, .day], from: today)
        year = c.year ?? year
        month = c.month ?? month
        selectedDay = c.day
    }

    func load() {
        do {
            transactions = try repo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var dailyNet: [Int: Money] {
        CalendarMath.dailyNet(transactions: transactions, year: year, month: month, calendar: calendar)
    }

    func transactions(onDay day: Int) -> [Transaction] {
        transactions.filter {
            let c = calendar.dateComponents([.year, .month, .day], from: $0.date)
            return c.year == year && c.month == month && c.day == day
        }
    }

    func step(_ delta: Int) {
        var m = month + delta
        var y = year
        if m < 1 { m = 12; y -= 1 }
        if m > 12 { m = 1; y += 1 }
        month = m
        year = y
    }

    var firstWeekday: Int {
        let comps = DateComponents(year: year, month: month, day: 1)
        guard let date = calendar.date(from: comps) else { return 1 }
        return calendar.component(.weekday, from: date) // 1 = Sunday
    }

    var daysInMonth: Int {
        let comps = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }
}
