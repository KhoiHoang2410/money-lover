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
                    ForEach(goal.schedule) { contribution in
                        LabeledContent("\(monthName(contribution.month)) \(String(contribution.year))") {
                            Text(contribution.amount.amount, format: .currency(code: "VND"))
                        }
                    }
                }
            }
            .navigationTitle(goal.name)
            .toolbar {
                Button("Add contribution", systemImage: "plus") { addingContribution = true }
            }
            .sheet(isPresented: $addingContribution) {
                ContributionSheet { store.addContribution(goalID: goalID, amount: $0) }
            }
        } else {
            ContentUnavailableView("Goal not found", systemImage: "questionmark.circle")
        }
    }

    private func monthName(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols[max(0, min(symbols.count - 1, month - 1))]
    }
}
