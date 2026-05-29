import SwiftUI

/// A goal's detail: target/saved/expected, ahead-behind, the schedule, and add-contribution.
struct GoalDetailScreen: View {
    let store: GoalsStore
    let goalID: UUID
    @State private var addingContribution = false

    var body: some View {
        if let goal = store.goal(id: goalID) {
            let progress = store.progress(for: goal)
            List {
                Section {
                    LabeledContent("Target") {
                        Text(goal.target.amount, format: .currency(code: goal.target.currency.rawValue))
                    }
                    LabeledContent("Saved") {
                        Text(store.contributed(for: goal).amount, format: .currency(code: "VND"))
                    }
                    LabeledContent("Expected by today") {
                        Text(progress.expected.amount, format: .currency(code: "VND"))
                    }
                    LabeledContent(progress.pct >= 0 ? "Ahead of plan" : "Behind plan") {
                        Text(abs(progress.pct), format: .percent.precision(.fractionLength(1)))
                            .foregroundStyle(progress.pct >= 0 ? Theme.Palette.ok : Theme.Palette.bad)
                    }
                }
                Section("Schedule") {
                    let status = store.scheduleStatus(for: goal)
                    ForEach(goal.schedule) { line in
                        GoalScheduleRow(line: line, status: status[line.id] ?? .pending)
                    }
                }
            }
            .navigationTitle(goal.name)
            .toolbar {
                Button("Add money", systemImage: "plus") { addingContribution = true }
            }
            .sheet(isPresented: $addingContribution) {
                ContributionSheet(accounts: store.fundingAccounts) { amount, accountID in
                    store.addContribution(goalID: goalID, amount: amount, fromAccountID: accountID)
                }
            }
        } else {
            ContentUnavailableView("Goal not found", systemImage: "questionmark.circle")
        }
    }
}
