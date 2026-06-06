import SwiftUI

/// Lists the owner's sources with balances and an add button.
struct SourcesList: View {
    let store: SourcesStore
    @State private var showingAdd = false

    var body: some View {
        List {
            ForEach(store.sources) { source in
                SourceRow(source: source, balance: store.balance(for: source))
            }
            .onDelete(perform: store.delete)
        }
        .overlay {
            if store.sources.isEmpty {
                ContentUnavailableView(
                    "No sources yet",
                    systemImage: "creditcard",
                    description: Text("Add your first account, card, or holding.")
                )
            }
        }
        .toolbar {
            Button("Add source", systemImage: "plus") {
                showingAdd = true
            }
            .accessibilityIdentifier(A11y.Source.add)
        }
        .sheet(isPresented: $showingAdd) {
            AddSourceScreen(onSave: store.add)
        }
    }
}
