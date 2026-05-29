import Testing
import Foundation
@testable import MoneyLover

@Suite struct TransferEngineTests {
    @Test func feeIsExpectedMinusReceived() {
        // S$600 at 18,500 = ₫11,100,000 expected; received ₫10,950,000 → fee ₫150,000.
        let fee = TransferEngine.fee(
            amountOut: Money(minorUnits: 600_00, currency: .sgd),
            amountIn: Money(minorUnits: 10_950_000, currency: .vnd),
            rate: 18_500
        )
        #expect(fee == Money(minorUnits: 150_000, currency: .vnd))
    }

    @Test func zeroFeeWhenRateMatches() {
        let fee = TransferEngine.fee(
            amountOut: Money(minorUnits: 100, currency: .usd),
            amountIn: Money(minorUnits: 25_500, currency: .vnd),
            rate: 25_500
        )
        #expect(fee.isZero)
    }

    @Test func crossCurrencyTransferMovesNativeAmounts() throws {
        let wise = Source(
            name: "Wise SGD", kind: .account, currency: .sgd,
            openingBalance: Money(minorUnits: 2_400_00, currency: .sgd), iconName: "globe"
        )
        let vpbank = Source(
            name: "VPBank", kind: .account, currency: .vnd,
            openingBalance: Money(minorUnits: 12_500_000, currency: .vnd), iconName: "bank"
        )
        let tx = Transaction(
            kind: .transfer,
            amount: Money(minorUnits: 600_00, currency: .sgd),
            sourceID: wise.id,
            destinationID: vpbank.id,
            destinationAmount: Money(minorUnits: 10_950_000, currency: .vnd)
        )
        // Source loses S$600; destination gains ₫10,950,000.
        #expect(try BalanceEngine.balance(of: wise, transactions: [tx]) == Money(minorUnits: 1_800_00, currency: .sgd))
        #expect(try BalanceEngine.balance(of: vpbank, transactions: [tx]) == Money(minorUnits: 23_450_000, currency: .vnd))
    }

    @Test func payCardReducesAccountAndDebt() throws {
        let account = Source(
            name: "MBBank", kind: .account, currency: .vnd,
            openingBalance: Money(minorUnits: 80_000_000, currency: .vnd), iconName: "bank"
        )
        let card = Source(
            name: "VPBank Credit", kind: .creditCard, currency: .vnd,
            openingBalance: Money(minorUnits: -18_300_000, currency: .vnd), iconName: "creditcard"
        )
        let tx = Transaction(
            kind: .transfer, amount: Money(minorUnits: 18_300_000, currency: .vnd),
            sourceID: account.id, destinationID: card.id
        )
        #expect(try BalanceEngine.balance(of: account, transactions: [tx]) == Money(minorUnits: 61_700_000, currency: .vnd))
        #expect(try BalanceEngine.balance(of: card, transactions: [tx]).isZero)
    }
}
