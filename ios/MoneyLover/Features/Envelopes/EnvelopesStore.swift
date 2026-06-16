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
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(envelopes: EnvelopeRepository, transactions: TransactionRepository) {
        self.envelopesRepo = envelopes
        self.transactionsRepo = transactions
        changeObserver.observe { [weak self] in self?.load() }
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

    /// Saves an in-place edit of an existing envelope (same id): allocation and weekly/monthly caps.
    func update(_ envelope: Envelope) {
        run { try envelopesRepo.update(envelope) }
    }

    /// VND spent against the envelope in the current calendar week (for weekly-cap display).
    func weekSpent(for envelope: Envelope) -> Money {
        EnvelopeCapEngine.spentThisWeek(envelopeID: envelope.id, transactions: transactions)
    }

    /// VND spent against the envelope in the current calendar month (for monthly-cap display).
    func monthSpent(for envelope: Envelope) -> Money {
        EnvelopeCapEngine.spentThisMonth(envelopeID: envelope.id, transactions: transactions)
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { envelopes[$0].id }
        run { for id in ids { try envelopesRepo.delete(id: id) } }
    }

    func makeReserve(_ envelope: Envelope) {
        run { try envelopesRepo.setReserve(id: envelope.id) }
    }

    /// True once any Envelope is the Reserve (the month-end catch-all).
    var hasReserve: Bool { envelopes.contains { $0.isReserve } }

    /// Normalized names of existing Envelopes, for graying out matching starter entries (feat 4).
    var existingNames: Set<String> { Set(envelopes.map { StarterEnvelope.key($0.name) }) }

    /// Adds the chosen Starter envelopes (name + icon, ₫0 Allocation). If no Reserve exists yet and
    /// the chosen set includes the designated one (Savings), that one becomes the Reserve (feat 4).
    func applyStarter(_ chosen: [StarterEnvelope]) {
        let existing = existingNames
        let assignReserve = !hasReserve
        run {
            var reserveID: UUID?
            for starter in chosen where !existing.contains(StarterEnvelope.key(starter.name)) {
                let envelope = Envelope(name: starter.name, iconName: starter.iconName, allocation: .zero(.vnd))
                try envelopesRepo.add(envelope)
                if assignReserve, starter.isReserveDefault, reserveID == nil { reserveID = envelope.id }
            }
            if let reserveID { try envelopesRepo.setReserve(id: reserveID) }
        }
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
