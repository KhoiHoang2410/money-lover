import Foundation
import Observation

/// View state for the Advice screen: builds a `FinanceSnapshot` from the repositories and
/// runs the deterministic `SignalEngine` over it.
@MainActor
@Observable
final class AdviceStore {
    private let envelopesRepo: EnvelopeRepository
    private let transactionsRepo: TransactionRepository
    private let goalsRepo: GoalRepository
    private(set) var signals: [Signal] = []
    var errorMessage: String?

    init(envelopes: EnvelopeRepository, transactions: TransactionRepository, goals: GoalRepository) {
        self.envelopesRepo = envelopes
        self.transactionsRepo = transactions
        self.goalsRepo = goals
    }

    func load() {
        do {
            let envelopes = try envelopesRepo.all()
            let transactions = try transactionsRepo.all()
            let goals = try goalsRepo.all().map {
                GoalState(goal: $0, actual: try goalsRepo.totalContributed(goalID: $0.id))
            }
            signals = SignalEngine.signals(
                FinanceSnapshot(envelopes: envelopes, transactions: transactions, goals: goals, asOf: .now)
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
