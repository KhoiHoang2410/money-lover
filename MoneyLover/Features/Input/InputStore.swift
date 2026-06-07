import Foundation
import Observation

/// View state for the Input feature: the sources available to pick, and saving transactions.
@MainActor
@Observable
final class InputStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let envelopesRepo: EnvelopeRepository
    private(set) var sources: [Source] = []
    private(set) var envelopes: [Envelope] = []
    private(set) var transactions: [Transaction] = []
    /// The owner's Holdings (gold, stock) — the trade destinations for an Invest (ADR-0010).
    var holdings: [Source] { sources.filter { $0.kind == .holding } }
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository, envelopes: EnvelopeRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.envelopesRepo = envelopes
        changeObserver.observe { [weak self] in self?.load() }
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            envelopes = try envelopesRepo.all()
            transactions = try transactionsRepo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func add(_ transaction: Transaction) {
        do {
            try transactionsRepo.add(transaction)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Records a forgotten *past* Expense/Income as an ordinary transaction, then restates the
    /// source's opening balance by the opposite amount so the *current* balance is unchanged
    /// (ADR-0012). The entry then shows on the calendar and counts everywhere a normal one does.
    /// `source.currency` always matches `transaction.amount.currency` (the form enforces it).
    func addBackfill(_ transaction: Transaction, source: Source) {
        do {
            var restated = source
            switch transaction.kind {
            case .expense: restated.openingBalance = try source.openingBalance.adding(transaction.amount)
            case .income: restated.openingBalance = try source.openingBalance.subtracting(transaction.amount)
            default: break
            }
            // Stage both writes and commit them in ONE save: a single atomic `didSave` so observing
            // stores reload a consistent state (never the opening restatement without its transaction,
            // or vice-versa).
            try sourcesRepo.stageUpdate(restated)
            transactionsRepo.stageAdd(transaction)
            try sourcesRepo.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Saves an in-place edit of an existing transaction (same id).
    func update(_ transaction: Transaction) {
        do {
            try transactionsRepo.update(transaction)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ transaction: Transaction) {
        do {
            try transactionsRepo.delete(id: transaction.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
