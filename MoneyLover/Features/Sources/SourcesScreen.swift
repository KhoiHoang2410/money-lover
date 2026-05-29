import SwiftUI
import SwiftData

/// Builds the `SourcesStore` from the environment's model context, then shows the list.
struct SourcesScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: SourcesStore?

    var body: some View {
        Group {
            if let store {
                SourcesList(store: store)
            } else {
                ProgressView()
                    .task {
                        let newStore = SourcesStore(
                            sources: SourceRepository(context: context),
                            transactions: TransactionRepository(context: context)
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Sources")
    }
}

#Preview {
    NavigationStack {
        SourcesScreen()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
