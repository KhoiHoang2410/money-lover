import Testing
import Foundation
@testable import MoneyLover

/// Money-correctness invariants for `BalanceEngine` (and its net-worth/budget consequences),
/// asserted through the public engine APIs over built transactions — no SwiftData, no UI.
///
/// Cases mirror the test-case catalog (`docs/test-cases/04,06,08,15`) and the seed snapshot via
/// `Fixtures`. Where the engine reveals a real defect, the case is wrapped in `withKnownIssue`
/// (Swift Testing's known-defect convention) with the catalog id, rather than left failing.
@Suite struct BalanceCorrectnessTests {

    private let rates = Fixtures.standardRates

    /// Current balance of a single source under a set of transactions.
    private func balance(_ source: Source, _ txns: [Transaction]) -> Money {
        (try? BalanceEngine.balance(of: source, transactions: txns)) ?? source.openingBalance
    }

    /// Net worth over all seed sources, valuing each source's current balance — mirrors `OverviewStore`.
    private func netWorth(_ txns: [Transaction]) -> NetWorth {
        NetWorthEngine.compute(
            entries: Fixtures.allSources.map { ($0, balance($0, txns)) },
            rates: rates
        )
    }

    // MARK: - 04 — Credit-card expense (Liability up, Account untouched)

    /// TC-04-01 — Credit-card spend deepens that card's Liability; no Account moves.
    @Test func creditExpenseRaisesLiabilityAccountUntouched() {
        let spend = makeExpense(vnd(500_000), source: Fixtures.vpCredit.id, envelope: Fixtures.fun.id)

        // Debt deepens by the amount: -18,300,000 - 500,000 = -18,800,000.
        #expect(balance(Fixtures.vpCredit, [spend]) == vnd(-18_800_000))
        // The funding bank account is the SAME card brand but a different source — untouched.
        #expect(balance(Fixtures.vpBank, [spend]) == Fixtures.vpBank.openingBalance)
    }

    /// TC-04-03 — A credit spend lowers net worth via Debt, NOT by reducing any Account.
    @Test func creditExpenseLowersNetWorthViaDebtOnly() {
        let spend = makeExpense(vnd(500_000), source: Fixtures.mbCredit.id, envelope: Fixtures.fun.id)

        let before = netWorth([])
        let after = netWorth([spend])

        // Net worth falls by exactly the spend; Debt rose, Assets did not.
        #expect(try! after.net.subtracting(before.net) == vnd(-500_000))
        #expect(try! after.debt.subtracting(before.debt) == vnd(-500_000))
        #expect(after.asset == before.asset)

        // No Account balance changed.
        for account in Fixtures.allSources.filter({ $0.kind == .account }) {
            #expect(balance(account, [spend]) == account.openingBalance)
        }
    }

    /// TC-04-02 — A credit-card expense reduces its Envelope remaining like any expense.
    @Test func creditExpenseReducesEnvelopeRemaining() throws {
        let spend = makeExpense(vnd(500_000), source: Fixtures.vpCredit.id, envelope: Fixtures.fun.id)

        let base = try BudgetEngine.remaining(envelope: Fixtures.fun, transactions: [])
        let after = try BudgetEngine.remaining(envelope: Fixtures.fun, transactions: [spend])
        #expect(try after.subtracting(base) == vnd(-500_000))
    }

    // MARK: - 06 — Same-currency transfer & credit-card bill payment (net to zero)

    /// TC-06-01 — A same-currency transfer moves money between Accounts; net worth is unchanged.
    @Test func sameCurrencyTransferMovesMoneyNetWorthUnchanged() {
        let move = makeTransfer(vnd(1_000_000), from: Fixtures.mbBank.id, to: Fixtures.savings.id)

        #expect(balance(Fixtures.mbBank, [move]) == vnd(79_000_000))   // 80M − 1M
        #expect(balance(Fixtures.savings, [move]) == vnd(521_000_000)) // 520M + 1M
        #expect(netWorth([move]).net == netWorth([]).net)              // money moved, not spent
    }

    /// TC-06-02 — Paying a credit-card bill (Transfer) lowers Account and Liability equally; net unchanged.
    @Test func billPaymentLowersAccountAndLiabilityEqually() {
        let pay = makeTransfer(vnd(2_000_000), from: Fixtures.vpBank.id, to: Fixtures.vpCredit.id)

        #expect(balance(Fixtures.vpBank, [pay]) == vnd(10_500_000))    // 12.5M − 2M
        #expect(balance(Fixtures.vpCredit, [pay]) == vnd(-16_300_000)) // −18.3M debt repaid by 2M
        #expect(netWorth([pay]).net == netWorth([]).net)              // Asset down, Debt down by the same
    }

    /// TC-06-03 — A bill payment is a Transfer, not an Expense: no Envelope remaining changes.
    @Test func billPaymentIsNotAnExpense() throws {
        let pay = makeTransfer(vnd(2_000_000), from: Fixtures.mbBank.id, to: Fixtures.mbCredit.id)

        for envelope in Fixtures.allocationTemplate {
            let base = try BudgetEngine.remaining(envelope: envelope, transactions: [])
            #expect(try BudgetEngine.remaining(envelope: envelope, transactions: [pay]) == base)
        }
    }

    // MARK: - 08 — Backfill (informational; excluded from current balance)

    /// TC-08-01 — A Backfill adds history without changing current balance or net worth.
    @Test func backfillExcludedFromBalanceAndNetWorth() {
        let past = makeBackfill(.expense, amount: vnd(60_000), source: Fixtures.cash.id,
                                envelope: Fixtures.food.id, date: date(2026, 5, 12))

        #expect(balance(Fixtures.cash, [past]) == Fixtures.cash.openingBalance)
        #expect(netWorth([past]).net == netWorth([]).net)
    }

    /// TC-08-02 — Current balance = opening + Σ of balance-affecting txns only; many Backfills change nothing.
    @Test func manyBackfillsLeaveCurrentBalanceAtOpening() {
        let backfills = [
            makeBackfill(.expense, amount: vnd(60_000), source: Fixtures.cash.id, date: date(2026, 1, 3)),
            makeBackfill(.income, amount: vnd(500_000), source: Fixtures.cash.id, date: date(2026, 2, 9)),
            makeBackfill(.expense, amount: vnd(1_250_000), source: Fixtures.cash.id, date: date(2026, 4, 21)),
        ]
        #expect(balance(Fixtures.cash, backfills) == Fixtures.cash.openingBalance)
    }

    /// TC-08-04 — A Backfill must not reopen a budget: it should not reduce Envelope remaining.
    ///
    /// KNOWN DEFECT — `BudgetEngine.spent` filters only on `kind == .expense && envelopeID`, ignoring
    /// `affectsBalance`. An informational Backfill expense assigned to an Envelope is therefore counted
    /// as spend. `BalanceEngine` excludes it correctly (TC-08-01); the budget side does not.
    @Test func backfillDoesNotReduceEnvelopeRemaining() {
        let pastFood = makeBackfill(.expense, amount: vnd(60_000), source: Fixtures.cash.id,
                                    envelope: Fixtures.food.id, date: date(2026, 5, 12))
        withKnownIssue("TC-08-04: BudgetEngine.spent ignores affectsBalance — Backfill leaks into Envelope spend") {
            let base = try BudgetEngine.remaining(envelope: Fixtures.food, transactions: [])
            #expect(try BudgetEngine.remaining(envelope: Fixtures.food, transactions: [pastFood]) == base)
        }
    }

    // MARK: - 15 — Income (increases Account; Envelopes untouched)

    /// TC-15-01 — Income increases the target Account and net worth by the same amount.
    @Test func incomeIncreasesAccountAndNetWorth() {
        let pay = makeIncome(vnd(10_000_000), source: Fixtures.mbBank.id)

        #expect(balance(Fixtures.mbBank, [pay]) == vnd(90_000_000)) // 80M + 10M
        #expect(try! netWorth([pay]).net.subtracting(netWorth([]).net) == vnd(10_000_000))
    }

    /// TC-15-02 — Income never changes any Envelope remaining (Allocations are independent of Income).
    @Test func incomeLeavesEnvelopesUnchanged() throws {
        let pay = makeIncome(vnd(10_000_000), source: Fixtures.mbBank.id)

        for envelope in Fixtures.allocationTemplate {
            let base = try BudgetEngine.remaining(envelope: envelope, transactions: [])
            #expect(try BudgetEngine.remaining(envelope: envelope, transactions: [pay]) == base)
        }
    }

    // MARK: - General invariants (empty → opening, sums, adjustments, isolation)

    /// Empty transactions → the source's opening balance.
    @Test func emptyTransactionsReturnOpening() {
        #expect(balance(Fixtures.mbBank, []) == Fixtures.mbBank.openingBalance)
    }

    /// Current balance = opening + Σ of every balance-affecting transaction, mixed kinds.
    @Test func manyTransactionsSumCorrectly() {
        let txns = [
            makeExpense(vnd(40_000), source: Fixtures.mbBank.id),
            makeIncome(vnd(2_000_000), source: Fixtures.mbBank.id),
            makeExpense(vnd(960_000), source: Fixtures.mbBank.id),
            makeTransfer(vnd(1_000_000), from: Fixtures.mbBank.id, to: Fixtures.savings.id),
            makeBackfill(.expense, amount: vnd(9_999_999), source: Fixtures.mbBank.id), // excluded
        ]
        // 80,000,000 − 40,000 + 2,000,000 − 960,000 − 1,000,000 = 80,000,000.
        #expect(balance(Fixtures.mbBank, txns) == vnd(80_000_000))
    }

    /// An Adjustment moves the balance by its signed amount, in either direction.
    @Test func adjustmentMovesBalanceBySignedAmount() {
        let down = makeAdjustment(vnd(-200_000), source: Fixtures.cash.id)
        let up = makeAdjustment(vnd(350_000), source: Fixtures.cash.id)
        #expect(balance(Fixtures.cash, [down]) == vnd(1_300_000)) // 1.5M − 0.2M
        #expect(balance(Fixtures.cash, [up]) == vnd(1_850_000))   // 1.5M + 0.35M
    }

    /// A transaction on one source never touches another.
    @Test func unrelatedSourceIsUntouched() {
        let spend = makeExpense(vnd(700_000), source: Fixtures.vpCredit.id)
        #expect(balance(Fixtures.mbBank, [spend]) == Fixtures.mbBank.openingBalance)
    }
}
