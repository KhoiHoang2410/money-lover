import Foundation
import Observation

/// View state for the Sources feature: loaded sources + transactions, with computed balances.
@MainActor
@Observable
final class SourcesStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private(set) var sources: [Source] = []
    private(set) var transactions: [Transaction] = []
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        changeObserver.observe { [weak self] in self?.load() }
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            transactions = try transactionsRepo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Accounts and cards only — Holdings live on the dedicated Holdings screen (ADR-0010).
    var manualSources: [Source] { sources.filter { $0.kind != .holding } }

    /// Current balance for a source (opening + balance-affecting transactions).
    func balance(for source: Source) -> Money {
        (try? BalanceEngine.balance(of: source, transactions: transactions)) ?? source.openingBalance
    }

    func add(_ source: Source) {
        do {
            try sourcesRepo.add(source)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes the manual sources at `offsets` within `manualSources`.
    func delete(at offsets: IndexSet) {
        let ids = offsets.map { manualSources[$0].id }
        do {
            for id in ids {
                try sourcesRepo.delete(id: id)
            }
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
