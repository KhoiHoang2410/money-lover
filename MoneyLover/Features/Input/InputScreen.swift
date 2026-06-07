import SwiftUI

/// The Input tab: a hub that routes to Expense / Income entry (more modes in later slices).
struct InputScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: InputStore?

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    InputHub(store: store)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Add")
            .navigationDestination(for: InputRoute.self) { route in
                if let store {
                    switch route {
                    case .transaction: TransactionForm(store: store)
                    case .reconcile: ReconcileScreen()
                    }
                }
            }
            .task {
                guard store == nil else { return }
                let newStore = InputStore(
                    sources: SourceRepository(context: context),
                    transactions: TransactionRepository(context: context),
                    envelopes: EnvelopeRepository(context: context)
                )
                newStore.load()
                store = newStore
                // No per-appearance reload: the store observes ModelContext (ADR-0009), so a Source
                // created in another tab surfaces in the pickers automatically.
            }
        }
    }
}

#Preview {
    InputScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
