import SwiftUI

/// Builds the `EnvelopesStore` from the environment, then shows the envelope list.
struct EnvelopesScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: EnvelopesStore?

    var body: some View {
        Group {
            if let store {
                EnvelopesList(store: store)
            } else {
                ProgressView()
                    .task {
                        let newStore = EnvelopesStore(
                            envelopes: EnvelopeRepository(context: context),
                            transactions: TransactionRepository(context: context)
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Envelopes")
    }
}
