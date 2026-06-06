import SwiftUI

/// Lists the owner's sources with balances, an add button, and tap-to-edit (update opening balance).
struct SourcesList: View {
    let store: SourcesStore
    @State private var sheet: SourceFormRoute?

    var body: some View {
        List {
            ForEach(store.manualSources) { source in
                // Tap-to-edit via onTapGesture (not Button) so the row's inner accessibility elements
                // stay individually addressable; the .isButton trait keeps VoiceOver correct.
                SourceRow(source: source, balance: store.balance(for: source))
                    .contentShape(Rectangle())
                    .onTapGesture { sheet = .edit(source) }
                    .accessibilityIdentifier(A11y.Source.row(source.name))
                    .accessibilityAddTraits(.isButton)
            }
            .onDelete(perform: store.delete)
        }
        .overlay {
            if store.manualSources.isEmpty {
                ContentUnavailableView(
                    "No sources yet",
                    systemImage: "creditcard",
                    description: Text("Add your first account or card.")
                )
            }
        }
        .toolbar {
            Button("Add source", systemImage: "plus") {
                sheet = .add
            }
            .accessibilityIdentifier(A11y.Source.add)
        }
        .sheet(item: $sheet) { route in
            switch route {
            case .add:
                AddSourceScreen(onSave: store.add)
            case .edit(let source):
                AddSourceScreen(editing: source, onSave: store.update)
            }
        }
    }
}
