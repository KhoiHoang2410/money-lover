import SwiftUI

/// The Overview tab: net worth with a censor toggle (hidden by default).
struct OverviewScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage("censorAmounts") private var censored = true
    @State private var store: OverviewStore?
    @State private var goalsStore: GoalsStore?

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    OverviewContent(store: store, censored: censored)
                } else {
                    ProgressView()
                        .task {
                            let newStore = OverviewStore(
                                sources: SourceRepository(context: context),
                                transactions: TransactionRepository(context: context),
                                rates: RatesRepository(context: context),
                                goals: GoalRepository(context: context)
                            )
                            newStore.load()
                            store = newStore
                            let goals = GoalsStore(
                                repo: GoalRepository(context: context),
                                sources: SourceRepository(context: context)
                            )
                            goals.load()
                            goalsStore = goals
                        }
                }
            }
            .navigationTitle("Overview")
            .navigationDestination(for: Source.self) { source in
                AccountHistoryScreen(account: source)
            }
            .navigationDestination(for: Goal.self) { goal in
                if let goalsStore {
                    GoalDetailScreen(store: goalsStore, goalID: goal.id)
                }
            }
            .onAppear {
                store?.load()
                goalsStore?.load()
            }
            .toolbar {
                Button(
                    censored ? "Show amounts" : "Hide amounts",
                    systemImage: censored ? "eye.slash" : "eye"
                ) {
                    censored.toggle()
                }
            }
        }
    }
}

#Preview {
    OverviewScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
