import Foundation
import Observation

/// View state for Goals: goals + total contributed, with progress (as of now).
@MainActor
@Observable
final class GoalsStore {
    private let repo: GoalRepository
    private let sourcesRepo: SourceRepository
    private(set) var goals: [Goal] = []
    /// VND Accounts that can fund a goal (ADR-0007 — foreign-currency Accounts are excluded).
    private(set) var fundingAccounts: [Source] = []
    private var totals: [UUID: Money] = [:]
    var errorMessage: String?

    init(repo: GoalRepository, sources: SourceRepository) {
        self.repo = repo
        self.sourcesRepo = sources
    }

    func load() {
        do {
            goals = try repo.all()
            fundingAccounts = try sourcesRepo.all().filter { $0.kind == .account && $0.currency == .vnd }
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

    /// Per-line funding status for a goal's schedule (green/gray/red).
    func scheduleStatus(for goal: Goal) -> [UUID: ScheduleStatus] {
        GoalTracker.scheduleStatus(schedule: goal.schedule, contributed: contributed(for: goal), asOf: .now)
    }

    func goal(id: UUID) -> Goal? { goals.first { $0.id == id } }

    func add(_ goal: Goal) { run { try repo.add(goal) } }
    func delete(at offsets: IndexSet) {
        let ids = offsets.map { goals[$0].id }
        run { for id in ids { try repo.delete(id: id) } }
    }
    func addContribution(goalID: UUID, amount: Money, fromAccountID: UUID) {
        let name = goal(id: goalID)?.name ?? "goal"
        run { try repo.addContribution(goalID: goalID, amount: amount, fromAccountID: fromAccountID, date: .now, note: "→ \(name)") }
    }

    private func run(_ work: () throws -> Void) {
        do { try work(); load() } catch { errorMessage = error.localizedDescription }
    }
}
