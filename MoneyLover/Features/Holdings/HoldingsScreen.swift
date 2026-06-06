import SwiftUI

/// Builds the `HoldingsStore` from the environment, then shows the holdings list.
struct HoldingsScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: HoldingsStore?

    var body: some View {
        Group {
            if let store {
                HoldingsList(store: store)
            } else {
                ProgressView()
                    .task {
                        let newStore = HoldingsStore(
                            sources: SourceRepository(context: context),
                            transactions: TransactionRepository(context: context),
                            rates: RatesRepository(context: context)
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Holdings")
    }
}
