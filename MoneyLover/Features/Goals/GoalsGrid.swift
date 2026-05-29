import SwiftUI

/// A two-column grid of goal rings plus an add button.
struct GoalsGrid: View {
    let store: GoalsStore
    @State private var showingAdd = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                ForEach(store.goals) { goal in
                    NavigationLink(value: goal.id) {
                        GoalRing(goal: goal, progress: store.progress(for: goal))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .overlay {
            if store.goals.isEmpty {
                ContentUnavailableView(
                    "No goals yet",
                    systemImage: "target",
                    description: Text("Add a savings goal with a monthly plan.")
                )
            }
        }
        .toolbar {
            Button("Add goal", systemImage: "plus") { showingAdd = true }
        }
        .sheet(isPresented: $showingAdd) {
            AddGoalScreen(onSave: store.add)
        }
    }
}
