import Testing
import Foundation
@testable import MoneyLover

/// Guards the fixtures themselves: they must mirror the seed snapshot and feed the Core engines
/// cleanly. Satisfies acceptance criterion #5 — the builders are referenced by a real test.
@Suite struct FixturesTests {

    // MARK: Snapshot fidelity

    @Test func reserveCarriesSeedAmount() {
        #expect(Fixtures.reserve.isReserve)
        #expect(Fixtures.reserve.allocation == vnd(0))
        #expect(Fixtures.reserve.carried == vnd(23_000_000))
    }

    @Test func houseGoalHasGapMonths() {
        // Jan–Mar, May, Jul–Sep — April and June are intentional gaps.
        #expect(Fixtures.houseGoal.schedule.map(\.month) == [1, 2, 3, 5, 7, 8, 9])
    }

    @Test func allSourcesCoverEveryKind() {
        let kinds = Set(Fixtures.allSources.map(\.kind))
        #expect(kinds == [.account, .creditCard, .holding])
    }

    @Test func creditCardsOpenAsDebt() {
        #expect(Fixtures.vpCredit.openingBalance.isNegative)
        #expect(Fixtures.mbCredit.openingBalance.isNegative)
    }

    // MARK: Builders feed the engines

    @Test func goldHoldingValuesThroughValuator() {
        // 5 chỉ × 15,950,000 = ₫79,750,000
        let value = Valuator.valueInVND(source: Fixtures.goldSJC, balance: .zero(.vnd), rates: Fixtures.standardRates)
        #expect(value == vnd(79_750_000))
    }

    @Test func balanceEngineSumsFixtureDeltas() throws {
        let account = Fixtures.mbBank
        let expense = makeExpense(vnd(45_000), source: account.id, envelope: Fixtures.food.id)
        let result = try BalanceEngine.current(opening: account.openingBalance, deltas: [expense.amount.negated])
        #expect(result == vnd(79_955_000))
    }

    @Test func backfillIsInformationalOnly() {
        let backfill = makeBackfill(amount: vnd(120_000), source: Fixtures.cash.id, envelope: Fixtures.food.id)
        #expect(backfill.affectsBalance == false)
    }

    @Test func contributionTargetsGoalWithoutDestinationSource() {
        let contribution = makeContribution(vnd(2_000_000), from: Fixtures.mbBank.id, goal: Fixtures.travelGoal.id)
        #expect(contribution.kind == .transfer)
        #expect(contribution.goalID == Fixtures.travelGoal.id)
        #expect(contribution.destinationID == nil)
    }
}
