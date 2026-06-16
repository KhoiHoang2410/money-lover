import Foundation
import Observation

/// View state for one account's transaction history: the filter controls and the filtered list.
@MainActor
@Observable
final class AccountHistoryStore {
    let account: Source
    private let repo: TransactionRepository
    private(set) var transactions: [Transaction] = []
    var range: HistoryRange = .week
    var kind: TransactionKind?
    var search = ""
    private let changeObserver = ModelChangeObserver()
    var errorMessage: String?

    init(account: Source, transactions: TransactionRepository) {
        self.account = account
        self.repo = transactions
        changeObserver.observe { [weak self] in self?.load() }
    }

    func load() {
        do {
            transactions = try repo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var entries: [Transaction] {
        TransactionHistory.entries(
            transactions: transactions,
            accountID: account.id,
            range: range,
            kind: kind,
            search: search
        )
    }
}
