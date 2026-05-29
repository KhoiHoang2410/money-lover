import SwiftUI

/// Builds an `EnvelopesStore` and shows the month-end sweep summary.
struct MonthEndScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: EnvelopesStore?

    var body: some View {
        Group {
            if let store {
                MonthEndSummary(store: store)
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
        .navigationTitle("Month-end sweep")
    }
}
