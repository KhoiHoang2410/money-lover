import Foundation
import Observation

/// View state for the Envelopes feature: envelopes + transactions, with computed spent/remaining.
@MainActor
@Observable
final class EnvelopesStore {
    private let envelopesRepo: EnvelopeRepository
    private let transactionsRepo: TransactionRepository
    private(set) var envelopes: [Envelope] = []
    private(set) var transactions: [Transaction] = []
    var errorMessage: String?

    init(envelopes: EnvelopeRepository, transactions: TransactionRepository) {
        self.envelopesRepo = envelopes
        self.transactionsRepo = transactions
    }

    func load() {
        do {
            envelopes = try envelopesRepo.all()
            transactions = try transactionsRepo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func spent(for envelope: Envelope) -> Money {
        BudgetEngine.spent(envelopeID: envelope.id, transactions: transactions)
    }

    func remaining(for envelope: Envelope) -> Money {
        (try? BudgetEngine.remaining(envelope: envelope, transactions: transactions)) ?? envelope.allocation
    }

    func add(_ envelope: Envelope) {
        run { try envelopesRepo.add(envelope) }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { envelopes[$0].id }
        run { for id in ids { try envelopesRepo.delete(id: id) } }
    }

    func makeReserve(_ envelope: Envelope) {
        run { try envelopesRepo.setReserve(id: envelope.id) }
    }

    /// The month-end sweep outcome for the currently loaded envelopes/transactions.
    func monthEndOutcome() -> MonthEndOutcome {
        let spentByEnvelope = Dictionary(uniqueKeysWithValues: envelopes.map { ($0.id, spent(for: $0)) })
        return (try? BudgetEngine.monthEnd(envelopes: envelopes, spentByEnvelope: spentByEnvelope))
            ?? MonthEndOutcome(lines: [], reserveDelta: .zero(.vnd))
    }

    /// Applies the sweep: adds the net leftover to the Reserve's carried amount.
    func applySweep() {
        let delta = monthEndOutcome().reserveDelta
        run { try envelopesRepo.sweepIntoReserve(delta: delta) }
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
