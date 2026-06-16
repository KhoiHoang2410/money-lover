import Testing
import Foundation
import SwiftData
@testable import MoneyLover

/// ADR-0012 — A Backfill is an ordinary transaction recorded together with an offsetting
/// opening-balance restatement, so the *current* balance never moves while the entry still shows
/// on the calendar and counts everywhere a normal one does. These exercise that at the store level
/// (the only place the two writes are coordinated).
@MainActor
@Suite struct InputStoreBackfillTests {
    private let cal = Calendar(identifier: .gregorian)

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Schema(AppSchema.models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeStore(_ context: ModelContext) -> (InputStore, SourceRepository, TransactionRepository) {
        let sources = SourceRepository(context: context)
        let transactions = TransactionRepository(context: context)
        let store = InputStore(
            sources: sources,
            transactions: transactions,
            envelopes: EnvelopeRepository(context: context),
            goals: GoalRepository(context: context)
        )
        return (store, sources, transactions)
    }

    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        cal.date(from: DateComponents(year: y, month: m, day: d))!
    }

    @Test func backfillExpenseRestatesOpeningAndKeepsCurrentBalance() throws {
        let context = try makeContext()
        let (store, sources, transactions) = makeStore(context)
        let cash = Source(name: "Cash", kind: .account, currency: .vnd,
                          openingBalance: vnd(1_000_000), iconName: "banknote")
        try sources.add(cash)

        let past = Transaction(date: date(2026, 5, 12), kind: .expense,
                               amount: vnd(60_000), sourceID: cash.id, note: "Forgot coffee")
        store.addBackfill(past, source: cash)

        let stored = try #require(try sources.all().first { $0.id == cash.id })
        let all = try transactions.all()

        // Opening restated UP by the expense, so the current balance is unchanged.
        #expect(stored.openingBalance == vnd(1_060_000))
        #expect(try BalanceEngine.balance(of: stored, transactions: all) == vnd(1_000_000))
        // The entry is an ordinary transaction: persisted and counted on its day in the grid.
        #expect(all.count == 1)
        #expect(CalendarMath.dailyNet(transactions: all, year: 2026, month: 5, calendar: cal)[12] == vnd(-60_000))
    }

    @Test func backfillIncomeRestatesOpeningAndKeepsCurrentBalance() throws {
        let context = try makeContext()
        let (store, sources, transactions) = makeStore(context)
        let cash = Source(name: "Cash", kind: .account, currency: .vnd,
                          openingBalance: vnd(1_000_000), iconName: "banknote")
        try sources.add(cash)

        let past = Transaction(date: date(2026, 5, 9), kind: .income,
                               amount: vnd(500_000), sourceID: cash.id, note: "Forgot refund")
        store.addBackfill(past, source: cash)

        let stored = try #require(try sources.all().first { $0.id == cash.id })
        let all = try transactions.all()

        // Opening restated DOWN by the income, so the current balance is unchanged.
        #expect(stored.openingBalance == vnd(500_000))
        #expect(try BalanceEngine.balance(of: stored, transactions: all) == vnd(1_000_000))
        #expect(CalendarMath.dailyNet(transactions: all, year: 2026, month: 5, calendar: cal)[9] == vnd(500_000))
    }
}
