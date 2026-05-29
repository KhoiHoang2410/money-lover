import Testing
import Foundation
@testable import MoneyLover

@Suite struct ReconcileServiceTests {
    private func account(opening: Int) -> Source {
        Source(
            name: "MBBank", kind: .account, currency: .vnd,
            openingBalance: Money(minorUnits: opening, currency: .vnd), iconName: "bank"
        )
    }

    @Test func equalBalanceProducesNoAdjustment() throws {
        let source = account(opening: 10_000_000)
        let adjustment = try ReconcileService.adjustment(
            for: source,
            transactions: [],
            realBalance: Money(minorUnits: 10_000_000, currency: .vnd)
        )
        #expect(adjustment == nil)
    }

    @Test func realHigherThanComputedAddsPositiveAdjustment() throws {
        // Computed 10,000,000; reality 10,050,000 → +50,000 adjustment.
        let source = account(opening: 10_000_000)
        let adjustment = try #require(try ReconcileService.adjustment(
            for: source,
            transactions: [],
            realBalance: Money(minorUnits: 10_050_000, currency: .vnd)
        ))
        #expect(adjustment.kind == .adjustment)
        #expect(adjustment.amount == Money(minorUnits: 50_000, currency: .vnd))
        #expect(adjustment.sourceID == source.id)
        #expect(adjustment.affectsBalance)
    }

    @Test func realLowerThanComputedAddsNegativeAdjustment() throws {
        // Forgotten small spends: reality is below computed → negative plug.
        let source = account(opening: 10_000_000)
        let adjustment = try #require(try ReconcileService.adjustment(
            for: source,
            transactions: [],
            realBalance: Money(minorUnits: 9_880_000, currency: .vnd)
        ))
        #expect(adjustment.amount == Money(minorUnits: -120_000, currency: .vnd))
    }

    @Test func adjustmentBringsComputedBalanceToReality() throws {
        let source = account(opening: 10_000_000)
        let spend = Transaction(
            kind: .expense, amount: Money(minorUnits: 200_000, currency: .vnd), sourceID: source.id
        )
        // Computed = 9,800,000; reality = 9,750,000 → adjustment of -50,000.
        let adjustment = try #require(try ReconcileService.adjustment(
            for: source,
            transactions: [spend],
            realBalance: Money(minorUnits: 9_750_000, currency: .vnd)
        ))
        #expect(adjustment.amount == Money(minorUnits: -50_000, currency: .vnd))
        let reconciled = try BalanceEngine.balance(of: source, transactions: [spend, adjustment])
        #expect(reconciled == Money(minorUnits: 9_750_000, currency: .vnd))
    }

    @Test func carriesNoteAndEnvelope() throws {
        let source = account(opening: 10_000_000)
        let envelopeID = UUID()
        let adjustment = try #require(try ReconcileService.adjustment(
            for: source,
            transactions: [],
            realBalance: Money(minorUnits: 9_900_000, currency: .vnd),
            envelopeID: envelopeID,
            note: "ATM fees"
        ))
        #expect(adjustment.envelopeID == envelopeID)
        #expect(adjustment.note == "ATM fees")
    }

    @Test func mismatchedCurrencyThrows() {
        let source = account(opening: 10_000_000)
        #expect(throws: MoneyError.self) {
            _ = try ReconcileService.adjustment(
                for: source,
                transactions: [],
                realBalance: Money(minorUnits: 400, currency: .usd)
            )
        }
    }
}
