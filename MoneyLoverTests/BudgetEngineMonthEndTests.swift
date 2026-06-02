import Testing
import Foundation
@testable import MoneyLover

@Suite struct BudgetEngineMonthEndTests {
    private func vnd(_ n: Int) -> Money { Money(minorUnits: n, currency: .vnd) }

    @Test func sumsLeftoversExcludingReserve() throws {
        let food = Envelope(name: "Food", iconName: "fork.knife", allocation: vnd(5_000_000))
        let fun = Envelope(name: "Fun", iconName: "sparkles", allocation: vnd(7_000_000))
        let reserve = Envelope(name: "Reserve", iconName: "star", allocation: vnd(0), isReserve: true)
        let spent = [food.id: vnd(4_600_000), fun.id: vnd(3_100_000), reserve.id: vnd(0)]

        let outcome = try BudgetEngine.monthEnd(envelopes: [food, fun, reserve], spentByEnvelope: spent)
        // food leftover 400k + fun leftover 3,900k = 4,300k. Reserve is excluded.
        #expect(outcome.reserveDelta == vnd(4_300_000))
        #expect(outcome.lines.count == 2)
    }

    @Test func overspendReducesReserveDelta() throws {
        let transport = Envelope(name: "Transport", iconName: "car", allocation: vnd(2_000_000))
        let outcome = try BudgetEngine.monthEnd(envelopes: [transport], spentByEnvelope: [transport.id: vnd(2_300_000)])
        #expect(outcome.reserveDelta == vnd(-300_000))
    }

    @Test func unspentEnvelopeContributesFullAllocation() throws {
        let rent = Envelope(name: "Rent", iconName: "house", allocation: vnd(8_000_000))
        let outcome = try BudgetEngine.monthEnd(envelopes: [rent], spentByEnvelope: [:])
        #expect(outcome.reserveDelta == vnd(8_000_000))
    }

    @Test func carriedRaisesRemaining() throws {
        let reserve = Envelope(name: "Reserve", iconName: "star", allocation: vnd(0), carried: vnd(23_000_000), isReserve: true)
        #expect(try BudgetEngine.remaining(envelope: reserve, transactions: []) == vnd(23_000_000))
    }

    // TC-12-05 (pure-engine determinism): monthEnd is pure, so calling it twice with
    // identical inputs returns identical reserveDelta and per-line leftovers. A caller
    // that re-runs the sweep computation for the same boundary computes the same result
    // (no internal mutation/accumulation makes the second call diverge).
    @Test func monthEndIsDeterministicAcrossRepeatedCalls() throws {
        let food = Envelope(name: "Food", iconName: "fork.knife", allocation: vnd(5_000_000))
        let transport = Envelope(name: "Transport", iconName: "car", allocation: vnd(2_000_000))
        let fun = Envelope(name: "Fun", iconName: "sparkles", allocation: vnd(7_000_000))
        let reserve = Envelope(name: "Reserve", iconName: "star", allocation: vnd(0), isReserve: true)
        let envelopes = [food, transport, fun, reserve]
        let spent = [
            food.id: vnd(4_880_000),       // +120,000 leftover
            transport.id: vnd(2_040_000),  // −40,000 overspend
            fun.id: vnd(6_990_000),        // +10,000 leftover
            reserve.id: vnd(0),
        ]

        let first = try BudgetEngine.monthEnd(envelopes: envelopes, spentByEnvelope: spent)
        let second = try BudgetEngine.monthEnd(envelopes: envelopes, spentByEnvelope: spent)

        // Net delta is identical (and not doubled): 120,000 − 40,000 + 10,000 = 90,000.
        #expect(first.reserveDelta == vnd(90_000))
        #expect(second.reserveDelta == first.reserveDelta)

        // Per-line leftovers match one-for-one across the two runs.
        #expect(second.lines.count == first.lines.count)
        for (a, b) in zip(first.lines, second.lines) {
            #expect(a.id == b.id)
            #expect(a.leftover == b.leftover)
        }
    }
}
