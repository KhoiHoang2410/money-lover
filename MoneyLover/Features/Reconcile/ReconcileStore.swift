import Foundation
import Observation

/// View state for Reconcile: the sources to re-balance, their computed Current balances,
/// and the envelopes an Adjustment can be charged to.
@MainActor
@Observable
final class ReconcileStore {
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let envelopesRepo: EnvelopeRepository
    private(set) var sources: [Source] = []
    private(set) var transactions: [Transaction] = []
    private(set) var envelopes: [Envelope] = []
    var errorMessage: String?
    /// Number of adjustments written by the last successful `record`, for confirmation.
    private(set) var lastRecordedCount: Int?

    init(sources: SourceRepository, transactions: TransactionRepository, envelopes: EnvelopeRepository) {
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.envelopesRepo = envelopes
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            transactions = try transactionsRepo.all()
            envelopes = try envelopesRepo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The balance computed from opening + transactions; falls back to opening on error.
    func computedBalance(for source: Source) -> Money {
        (try? BalanceEngine.balance(of: source, transactions: transactions)) ?? source.openingBalance
    }

    /// The Adjustment for a single source's real balance, or nil when it already matches.
    func adjustment(for source: Source, realBalance: Money, envelopeID: UUID?, note: String) -> Transaction? {
        do {
            return try ReconcileService.adjustment(
                for: source,
                transactions: transactions,
                realBalance: realBalance,
                envelopeID: envelopeID,
                note: note
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    /// Persists the adjustments and reloads, so the screen's diffs reset to zero.
    func record(_ adjustments: [Transaction]) {
        guard !adjustments.isEmpty else { return }
        do {
            for adjustment in adjustments {
                try transactionsRepo.add(adjustment)
            }
            lastRecordedCount = adjustments.count
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
