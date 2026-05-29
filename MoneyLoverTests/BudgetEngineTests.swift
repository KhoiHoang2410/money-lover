import Testing
import Foundation
@testable import MoneyLover

@Suite struct BudgetEngineTests {
    private let food = Envelope(
        name: "Food", iconName: "fork.knife",
        allocation: Money(minorUnits: 5_000_000, currency: .vnd)
    )

    @Test func remainingIsAllocationMinusSpent() throws {
        let txs = [
            Transaction(kind: .expense, amount: Money(minorUnits: 40_000, currency: .vnd), sourceID: UUID(), note: "", envelopeID: food.id),
            Transaction(kind: .expense, amount: Money(minorUnits: 360_000, currency: .vnd), sourceID: UUID(), note: "", envelopeID: food.id)
        ]
        #expect(try BudgetEngine.remaining(envelope: food, transactions: txs) == Money(minorUnits: 4_600_000, currency: .vnd))
    }

    @Test func overspendingGivesNegativeRemaining() throws {
        let txs = [Transaction(kind: .expense, amount: Money(minorUnits: 5_300_000, currency: .vnd), sourceID: UUID(), envelopeID: food.id)]
        let remaining = try BudgetEngine.remaining(envelope: food, transactions: txs)
        #expect(remaining == Money(minorUnits: -300_000, currency: .vnd))
        #expect(remaining.isNegative)
    }

    @Test func onlyCountsExpensesAssignedToThisEnvelope() {
        let other = UUID()
        let txs = [
            Transaction(kind: .expense, amount: Money(minorUnits: 100_000, currency: .vnd), sourceID: UUID(), envelopeID: food.id),
            Transaction(kind: .expense, amount: Money(minorUnits: 999_000, currency: .vnd), sourceID: UUID(), envelopeID: other),
            Transaction(kind: .income, amount: Money(minorUnits: 500_000, currency: .vnd), sourceID: UUID(), envelopeID: food.id)
        ]
        #expect(BudgetEngine.spent(envelopeID: food.id, transactions: txs) == Money(minorUnits: 100_000, currency: .vnd))
    }

    @Test func noMatchingExpensesIsZeroSpent() {
        #expect(BudgetEngine.spent(envelopeID: food.id, transactions: []).isZero)
    }
}
