import Foundation
import Observation

/// View state for the Overview: sources, balances, and net-worth in VND.
@MainActor
@Observable
final class OverviewStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let ratesRepo: RatesRepository
    private let goalsRepo: GoalRepository
    private(set) var sources: [Source] = []
    private(set) var transactions: [Transaction] = []
    private(set) var goals: [Goal] = []
    private(set) var rates: Rates = .empty
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository, rates: RatesRepository, goals: GoalRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.ratesRepo = rates
        self.goalsRepo = goals
        changeObserver.observe { [weak self] in self?.load() }
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            transactions = try transactionsRepo.all()
            goals = try goalsRepo.all()
            rates = try ratesRepo.snapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func balance(for source: Source) -> Money {
        (try? BalanceEngine.balance(of: source, transactions: transactions)) ?? source.openingBalance
    }

    /// The amount shown on a source's row, in VND: a Holding's value is live quantity × Rate
    /// (its money balance is always zero), while Accounts/cards show their own-currency balance.
    func displayValue(for source: Source) -> Money {
        switch source.kind {
        case .holding:
            let resolved = HoldingQuantityEngine.resolved(source, transactions: transactions)
            return Valuator.valueInVND(source: resolved, balance: .zero(.vnd), rates: rates)
        case .account, .creditCard:
            return balance(for: source)
        }
    }

    /// A Goal's balance in VND — the money funded into it (ADR-0007).
    func balance(for goal: Goal) -> Money {
        GoalTracker.contributed(goalID: goal.id, transactions: transactions)
    }

    var accounts: [Source] { sources.filter { $0.kind == .account } }
    var holdings: [Source] { sources.filter { $0.kind == .holding } }
    var cards: [Source] { sources.filter { $0.kind == .creditCard } }
    /// Goals that hold money, shown as an Asset section.
    var fundedGoals: [Goal] { goals.filter { balance(for: $0).minorUnits > 0 } }

    var netWorth: NetWorth {
        // Resolve each Holding to its live quantity so the Valuator values current units; Accounts
        // and cards are returned unchanged and still carry their money balance (ADR-0010).
        NetWorthEngine.compute(
            entries: sources.map { (HoldingQuantityEngine.resolved($0, transactions: transactions), balance(for: $0)) },
            rates: rates,
            goalBalances: goals.map { balance(for: $0) }
        )
    }
}
