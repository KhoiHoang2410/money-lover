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
                    LabeledContent("Plan") {
                        Text("\(Self.monthLabel(goal.startMonth)) – \(Self.monthLabel(goal.endMonth))")
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
                    let shortfalls = store.shortfalls(for: goal)
                    let byMonth = Dictionary(grouping: store.contributions(for: goal)) { Self.monthKey($0.date) }
                    ForEach(goal.schedule) { line in
                        GoalScheduleRow(
                            line: line,
                            status: status[line.id] ?? .pending,
                            shortfall: shortfalls[line.id],
                            contributions: byMonth[line.year * 12 + line.month] ?? []
                        )
                    }
                }
            }
            .navigationTitle(goal.name)
            .toolbar {
                Button("Add money", systemImage: "plus") { addingContribution = true }
                    .accessibilityIdentifier(A11y.Goals.detailContribute)
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

    /// `year * 12 + month` for a date — the key that ties a Contribution to its Schedule line.
    private static func monthKey(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return (c.year ?? 0) * 12 + (c.month ?? 0)
    }

    /// Short month + year label, e.g. "Jan 2026".
    private static func monthLabel(_ ym: YearMonth) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        let name = symbols[max(0, min(symbols.count - 1, ym.month - 1))]
        return "\(name) \(ym.year)"
    }
}
