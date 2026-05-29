import SwiftUI

/// The Overview tab: net worth with a censor toggle (hidden by default).
struct OverviewScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage("censorAmounts") private var censored = true
    @State private var store: OverviewStore?

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
                                rates: RatesRepository(context: context)
                            )
                            newStore.load()
                            store = newStore
                        }
                }
            }
            .navigationTitle("Overview")
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
