import SwiftUI

/// Lists the owner's Holdings (gold & stock) with live quantity and VND value, plus an add button.
struct HoldingsList: View {
    let store: HoldingsStore
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(store.holdings) { holding in
                HoldingRow(
                    holding: holding,
                    quantity: store.liveQuantity(for: holding),
                    value: store.value(for: holding)
                )
            }
            .onDelete(perform: store.delete)
        }
        .overlay {
            if store.holdings.isEmpty {
                ContentUnavailableView(
                    "No holdings yet",
                    systemImage: "chart.pie",
                    description: Text("Add the gold or stock you own — value updates from live prices.")
                )
            }
        }
        .toolbar {
            Button("Add holding", systemImage: "plus") { showingAdd = true }
                .accessibilityIdentifier(A11y.Holding.add)
        }
        .sheet(isPresented: $showingAdd) {
            AddHoldingScreen(onSave: store.add)
        }
    }
}
