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
}
