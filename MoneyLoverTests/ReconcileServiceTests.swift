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

    // TC-07-04 — Multi-source reconcile in one pass: one Adjustment per CHANGED source,
    // nil for an unchanged source. Each adjustment's sourceID matches its source and its
    // signed amount == realBalance − computed.
    @Test func multiSourceReconcileYieldsOneAdjustmentPerChangedSource() throws {
        let a = Source(name: "A", kind: .account, currency: .vnd,
                       openingBalance: Money(minorUnits: 10_000_000, currency: .vnd), iconName: "bank")
        let b = Source(name: "B", kind: .account, currency: .vnd,
                       openingBalance: Money(minorUnits: 5_000_000, currency: .vnd), iconName: "bank")
        let c = Source(name: "C", kind: .account, currency: .vnd,
                       openingBalance: Money(minorUnits: 2_000_000, currency: .vnd), iconName: "bank")

        // One shared ledger; BalanceEngine filters per source id.
        let spendB = Transaction(
            kind: .expense, amount: Money(minorUnits: 300_000, currency: .vnd), sourceID: b.id
        )
        let transactions = [spendB]

        // A: computed 10,000,000, reality 10,000,000 → unchanged (nil).
        // B: computed 5,000,000 − 300,000 = 4,700,000, reality 4,650,000 → −50,000.
        // C: computed 2,000,000, reality 2,075,000 → +75,000.
        let realBalances: [UUID: Money] = [
            a.id: Money(minorUnits: 10_000_000, currency: .vnd),
            b.id: Money(minorUnits: 4_650_000, currency: .vnd),
            c.id: Money(minorUnits: 2_075_000, currency: .vnd),
        ]

        var adjustments: [Transaction] = []
        for source in [a, b, c] {
            if let adj = try ReconcileService.adjustment(
                for: source,
                transactions: transactions,
                realBalance: realBalances[source.id]!
            ) {
                adjustments.append(adj)
            }
        }

        // Exactly two adjustments (B and C); A is unchanged → nil.
        #expect(adjustments.count == 2)
        #expect(!adjustments.contains { $0.sourceID == a.id })

        let adjB = try #require(adjustments.first { $0.sourceID == b.id })
        let adjC = try #require(adjustments.first { $0.sourceID == c.id })

        #expect(adjB.kind == .adjustment)
        #expect(adjB.amount == Money(minorUnits: -50_000, currency: .vnd))
        #expect(adjC.kind == .adjustment)
        #expect(adjC.amount == Money(minorUnits: 75_000, currency: .vnd))

        // Each adjustment, applied with the shared ledger, brings its source to reality.
        let reconciledB = try BalanceEngine.balance(of: b, transactions: transactions + [adjB])
        #expect(reconciledB == realBalances[b.id]!)
        let reconciledC = try BalanceEngine.balance(of: c, transactions: transactions + [adjC])
        #expect(reconciledC == realBalances[c.id]!)
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
