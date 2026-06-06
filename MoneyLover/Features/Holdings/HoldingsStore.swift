import Foundation
import Observation

/// View state for the dedicated Holdings screen: the Holding sources, their live quantity
/// (opening ± Invest trades, ADR-0010), and their current VND value.
@MainActor
@Observable
final class HoldingsStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let ratesRepo: RatesRepository
    private(set) var holdings: [Source] = []
    private(set) var transactions: [Transaction] = []
    private(set) var rates: Rates = .empty
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
            holdings = try sourcesRepo.all().filter { $0.kind == .holding }
            transactions = try transactionsRepo.all()
            rates = try ratesRepo.snapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The Holding's live quantity = opening quantity + Σ Buys − Σ Sells.
    func liveQuantity(for holding: Source) -> Decimal {
        HoldingQuantityEngine.liveQuantity(of: holding, transactions: transactions)
    }

    /// The Holding's current value in VND (live quantity × Rate).
    func value(for holding: Source) -> Money {
        let resolved = HoldingQuantityEngine.resolved(holding, transactions: transactions)
        return Valuator.valueInVND(source: resolved, balance: .zero(.vnd), rates: rates)
    }

    func add(_ source: Source) {
        run { try sourcesRepo.add(source) }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { holdings[$0].id }
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
