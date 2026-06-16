import Foundation
import Observation

/// View state for the Sources feature: loaded sources + transactions, with computed balances.
@MainActor
@Observable
final class SourcesStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let ratesRepo: RatesRepository
    private(set) var sources: [Source] = []
    private(set) var transactions: [Transaction] = []
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository, rates: RatesRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.ratesRepo = rates
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
        run {
            try sourcesRepo.add(source)
            // A non-VND account needs an fx rate to value in VND — seed a placeholder so it shows up
            // on the Rates screen straight away (feat: auto-add rate for new currency).
            try ratesRepo.ensure(keys: RateKeys.required(for: source))
        }
    }

    /// Saves an in-place edit of an existing source (same id), e.g. an updated opening balance.
    func update(_ source: Source) {
        run {
            try sourcesRepo.update(source)
            try ratesRepo.ensure(keys: RateKeys.required(for: source))
        }
    }

    /// Deletes the manual sources at `offsets` within `manualSources`.
    func delete(at offsets: IndexSet) {
        let ids = offsets.map { manualSources[$0].id }
        run { for id in ids { try sourcesRepo.delete(id: id) } }
    }

    private func run(_ work: () throws -> Void) {
        do {
            try work()
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
