import Testing
import Foundation
@testable import MoneyLover

@Suite struct TransactionHistoryTests {
    private let cal = Calendar(identifier: .gregorian)
    private let asOf = Date(timeIntervalSince1970: 1_750_000_000) // fixed "now"
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }
    private func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: asOf)! }

    private let account = UUID()
    private let other = UUID()

    private func txns() -> [Transaction] {
        [
            Transaction(date: daysAgo(1), kind: .expense, amount: vnd(40_000), sourceID: account, note: "Bánh mì"),
            Transaction(date: daysAgo(3), kind: .income, amount: vnd(80_000_000), sourceID: account, note: "Salary"),
            Transaction(date: daysAgo(10), kind: .transfer, amount: vnd(1_000_000), sourceID: other, destinationID: account, note: "Transfer in"),
            Transaction(date: daysAgo(40), kind: .expense, amount: vnd(2_000_000), sourceID: account, note: "Old rent"),
            Transaction(date: daysAgo(2), kind: .expense, amount: vnd(5_000), sourceID: other, note: "Not mine")
        ]
    }

    @Test func includesOnlyTransactionsTouchingTheAccount() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, asOf: asOf, calendar: cal)
        #expect(result.count == 4)                       // excludes the `other`-only expense
        #expect(result.allSatisfy { $0.note != "Not mine" })
    }

    @Test func includesTransfersInAsDestination() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, asOf: asOf, calendar: cal)
        #expect(result.contains { $0.note == "Transfer in" })
    }

    @Test func weekRangeExcludesOlder() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .week, asOf: asOf, calendar: cal)
        // Within 7 days: Bánh mì (1) + Salary (3). Transfer (10) and Old rent (40) excluded.
        #expect(result.count == 2)
    }

    @Test func newestFirst() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, asOf: asOf, calendar: cal)
        #expect(result.first?.note == "Bánh mì")
    }

    @Test func kindFilterLimitsToOneKind() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, kind: .expense, asOf: asOf, calendar: cal)
        #expect(result.allSatisfy { $0.kind == .expense })
        #expect(result.count == 2)                       // Bánh mì + Old rent
    }

    @Test func searchMatchesNoteCaseInsensitively() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, search: "salary", asOf: asOf, calendar: cal)
        #expect(result.count == 1)
        #expect(result.first?.note == "Salary")
    }

    @Test func blankSearchKeepsAll() {
        let result = TransactionHistory.entries(transactions: txns(), accountID: account, range: .all, search: "   ", asOf: asOf, calendar: cal)
        #expect(result.count == 4)
    }
}
