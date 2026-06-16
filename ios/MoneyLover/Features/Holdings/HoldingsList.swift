import SwiftUI

/// Lists the owner's Holdings (gold & stock) with live quantity and VND value, an add button, and
/// tap-to-edit (update opening quantity).
struct HoldingsList: View {
    let store: HoldingsStore
    @State private var sheet: HoldingFormRoute?

    var body: some View {
        List {
            ForEach(store.holdings) { holding in
                // Tap-to-edit via onTapGesture. `.accessibilityElement(children: .combine)` collapses
                // the row's icon / name / quantity / value into ONE element (label = their text
                // joined) carrying the row identifier — the same single-element shape Overview's
                // NavigationLink rows get. Without it, `.accessibilityIdentifier` on the multi-child
                // row propagates that id onto every leaf, so each piece becomes a separate button
                // sharing `holding.row.<name>` and the name surfaces as a button rather than static
                // text (a UI test asserting the holding appeared can't then find it).
                HoldingRow(
                    holding: holding,
                    quantity: store.liveQuantity(for: holding),
                    value: store.value(for: holding)
                )
                .contentShape(Rectangle())
                .onTapGesture { sheet = .edit(holding) }
                .accessibilityElement(children: .combine)
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
