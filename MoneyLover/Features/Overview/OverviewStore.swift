import Foundation
import Observation

/// View state for the Overview: sources, balances, and net-worth in VND.
@MainActor
@Observable
final class OverviewStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let ratesRepo: RatesRepository
    private(set) var sources: [Source] = []
    private(set) var transactions: [Transaction] = []
    private(set) var rates: Rates = .empty
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository, rates: RatesRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.ratesRepo = rates
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            transactions = try transactionsRepo.all()
            rates = try ratesRepo.snapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func balance(for source: Source) -> Money {
        (try? BalanceEngine.balance(of: source, transactions: transactions)) ?? source.openingBalance
    }

    var accounts: [Source] { sources.filter { $0.kind == .account } }
    var holdings: [Source] { sources.filter { $0.kind == .holding } }
    var cards: [Source] { sources.filter { $0.kind == .creditCard } }

    var netWorth: NetWorth {
        NetWorthEngine.compute(entries: sources.map { ($0, balance(for: $0)) }, rates: rates)
    }
}
