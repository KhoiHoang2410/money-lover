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
            .navigationDestination(for: OverviewRoute.self) { route in
                switch route {
                case .account(let id):
                    if let source = store?.sources.first(where: { $0.id == id }) {
                        AccountHistoryScreen(account: source)
                    }
                case .goal(let id):
                    if let goalsStore {
                        GoalDetailScreen(store: goalsStore, goalID: id)
                    }
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
                .accessibilityIdentifier(A11y.Overview.censorToggle)
            }
        }
    }
}

#Preview {
    OverviewScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
