import SwiftUI

/// Lists the owner's Holdings (gold & stock) with live quantity and VND value, an add button, and
/// tap-to-edit (update opening quantity).
struct HoldingsList: View {
    let store: HoldingsStore
    @State private var sheet: HoldingFormRoute?

    var body: some View {
        List {
            ForEach(store.holdings) { holding in
                // Tap-to-edit via onTapGesture (not Button) so the row's inner value element stays
                // individually addressable; the .isButton trait keeps VoiceOver correct.
                HoldingRow(
                    holding: holding,
                    quantity: store.liveQuantity(for: holding),
                    value: store.value(for: holding)
                )
                .contentShape(Rectangle())
                .onTapGesture { sheet = .edit(holding) }
                .accessibilityIdentifier(A11y.Holding.row(holding.name))
                .accessibilityAddTraits(.isButton)
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
            Button("Add holding", systemImage: "plus") { sheet = .add }
                .accessibilityIdentifier(A11y.Holding.add)
        }
        .sheet(item: $sheet) { route in
            switch route {
            case .add:
                AddHoldingScreen(onSave: store.add)
            case .edit(let holding):
                AddHoldingScreen(editing: holding, onSave: store.update)
            }
        }
    }
}
