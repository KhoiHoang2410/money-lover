import SwiftUI

/// Builds the `RatesStore` (tickers come from holdings) and shows the rates list.
struct RatesScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: RatesStore?

    var body: some View {
        Group {
            if let store {
                RatesList(store: store)
            } else {
                ProgressView()
                    .task {
                        let sources = (try? SourceRepository(context: context).all()) ?? []
                        let tickers = sources.compactMap { $0.holding?.ticker }
                        let newStore = RatesStore(
                            repo: RatesRepository(context: context),
                            provider: LivePriceProvider(),
                            tickers: tickers
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Rates & prices")
    }
}
