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
    var errorMessage: String?

    init(sources: SourceRepository, transactions: TransactionRepository, envelopes: EnvelopeRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.envelopesRepo = envelopes
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
}
