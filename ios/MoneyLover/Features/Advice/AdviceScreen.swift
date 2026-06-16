import SwiftUI

/// The Advice screen: lists current rule-based Signals, strongest first. Pushed from Config,
/// so it carries no `NavigationStack` of its own.
struct AdviceScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: AdviceStore?

    var body: some View {
        Group {
            if let store {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        ForEach(store.signals) { signal in
                            SignalCard(signal: signal)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Layout.bottomInset)
                }
                .overlay {
                    if store.signals.isEmpty {
                        ContentUnavailableView(
                            "All on track",
                            systemImage: "checkmark.seal.fill",
                            description: Text("No spending or goal concerns right now.")
                        )
                    }
                }
            } else {
                ProgressView()
                    .task {
                        guard store == nil else { return }
                        let newStore = AdviceStore(
                            envelopes: EnvelopeRepository(context: context),
                            transactions: TransactionRepository(context: context),
                            goals: GoalRepository(context: context)
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Advice")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AdviceScreen()
            .modelContainer(for: AppSchema.models, inMemory: true)
    }
}
