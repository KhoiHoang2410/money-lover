import SwiftUI

/// The Goals tab: builds the store and shows the ring grid, with push to detail.
struct GoalsScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: GoalsStore?

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    GoalsGrid(store: store)
                } else {
                    ProgressView()
                        .task {
                            let newStore = GoalsStore(repo: GoalRepository(context: context))
                            newStore.load()
                            store = newStore
                        }
                }
            }
            .navigationTitle("Goals")
            .navigationDestination(for: UUID.self) { id in
                if let store {
                    GoalDetailScreen(store: store, goalID: id)
                }
            }
        }
    }
}

#Preview {
    GoalsScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
