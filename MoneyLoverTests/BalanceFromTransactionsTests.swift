import Testing
import Foundation
@testable import MoneyLover

@Suite struct BalanceFromTransactionsTests {
    private let account = Source(
        name: "MBBank", kind: .account, currency: .vnd,
        openingBalance: Money(minorUnits: 80_000_000, currency: .vnd), iconName: "bank"
    )
    private let card = Source(
        name: "VPBank Credit", kind: .creditCard, currency: .vnd,
        openingBalance: Money(minorUnits: -18_300_000, currency: .vnd), iconName: "creditcard"
    )

    @Test func expenseReducesAccount() throws {
        let tx = Transaction(kind: .expense, amount: Money(minorUnits: 40_000, currency: .vnd), sourceID: account.id)
        #expect(try BalanceEngine.balance(of: account, transactions: [tx]) == Money(minorUnits: 79_960_000, currency: .vnd))
    }

    @Test func incomeIncreasesAccount() throws {
        let tx = Transaction(kind: .income, amount: Money(minorUnits: 80_000_000, currency: .vnd), sourceID: account.id)
        #expect(try BalanceEngine.balance(of: account, transactions: [tx]) == Money(minorUnits: 160_000_000, currency: .vnd))
    }

    @Test func expenseOnCreditCardIncreasesDebt() throws {
        let tx = Transaction(kind: .expense, amount: Money(minorUnits: 700_000, currency: .vnd), sourceID: card.id)
        // Debt deepens: -18,300,000 - 700,000 = -19,000,000
        #expect(try BalanceEngine.balance(of: card, transactions: [tx]) == Money(minorUnits: -19_000_000, currency: .vnd))
    }

    @Test func unrelatedTransactionDoesNotAffectSource() throws {
        let tx = Transaction(kind: .expense, amount: Money(minorUnits: 1, currency: .vnd), sourceID: card.id)
        #expect(try BalanceEngine.balance(of: account, transactions: [tx]) == account.openingBalance)
    }

    @Test func transferMovesBetweenSources() throws {
        let tx = Transaction(kind: .transfer, amount: Money(minorUnits: 5_000_000, currency: .vnd), sourceID: account.id, destinationID: card.id)
        #expect(try BalanceEngine.balance(of: account, transactions: [tx]) == Money(minorUnits: 75_000_000, currency: .vnd))
        #expect(try BalanceEngine.balance(of: card, transactions: [tx]) == Money(minorUnits: -13_300_000, currency: .vnd))
    }

    @Test func sumsMultipleTransactions() throws {
        let txs = [
            Transaction(kind: .expense, amount: Money(minorUnits: 40_000, currency: .vnd), sourceID: account.id),
            Transaction(kind: .income, amount: Money(minorUnits: 1_040_000, currency: .vnd), sourceID: account.id)
        ]
        #expect(try BalanceEngine.balance(of: account, transactions: txs) == Money(minorUnits: 81_000_000, currency: .vnd))
    }
}
