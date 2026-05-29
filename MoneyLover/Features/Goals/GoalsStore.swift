import Foundation
import Observation

/// View state for Goals: goals + total contributed, with progress (as of now).
@MainActor
@Observable
final class GoalsStore {
    private let repo: GoalRepository
    private(set) var goals: [Goal] = []
    private var totals: [UUID: Money] = [:]
    var errorMessage: String?

    init(repo: GoalRepository) {
        self.repo = repo
    }

    func load() {
        do {
            goals = try repo.all()
            totals = Dictionary(uniqueKeysWithValues: try goals.map {
                ($0.id, try repo.totalContributed(goalID: $0.id))
            })
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func contributed(for goal: Goal) -> Money { totals[goal.id] ?? .zero(.vnd) }

    func progress(for goal: Goal) -> GoalProgress {
        GoalTracker.progress(goal: goal, actual: contributed(for: goal), asOf: .now)
    }

    func goal(id: UUID) -> Goal? { goals.first { $0.id == id } }

    func add(_ goal: Goal) { run { try repo.add(goal) } }
    func delete(at offsets: IndexSet) {
        let ids = offsets.map { goals[$0].id }
        run { for id in ids { try repo.delete(id: id) } }
    }
    func addContribution(goalID: UUID, amount: Money) {
        run { try repo.addContribution(goalID: goalID, amount: amount, date: .now) }
    }

    private func run(_ work: () throws -> Void) {
        do { try work(); load() } catch { errorMessage = error.localizedDescription }
    }
}
