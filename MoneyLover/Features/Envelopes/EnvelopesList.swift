import SwiftUI

/// Lists envelopes with spent/remaining, tap-to-edit (adjust caps), swipe-to-set-Reserve, and add.
struct EnvelopesList: View {
    let store: EnvelopesStore
    @State private var sheet: EnvelopeSheetRoute?

    var body: some View {
        List {
            ForEach(store.envelopes) { envelope in
                // Tap-to-edit via onTapGesture (not Button) so the row's inner "remaining" element
                // stays individually addressable; the .isButton trait keeps VoiceOver correct.
                EnvelopeRow(
                    envelope: envelope,
                    spent: store.spent(for: envelope),
                    remaining: store.remaining(for: envelope),
                    weekSpent: store.weekSpent(for: envelope),
                    monthSpent: store.monthSpent(for: envelope)
                )
                .contentShape(Rectangle())
                .onTapGesture { sheet = .edit(envelope) }
                .accessibilityIdentifier(A11y.Envelope.row(envelope.name))
                .accessibilityAddTraits(.isButton)
                .swipeActions(edge: .leading) {
                    Button("Reserve", systemImage: "star.fill") {
                        store.makeReserve(envelope)
                    }
                    .tint(Theme.Palette.yellowDeep)
                }
            }
            .onDelete(perform: store.delete)
        }
        .overlay {
            if store.envelopes.isEmpty {
                ContentUnavailableView {
                    Label("No envelopes", systemImage: "tray.full")
                } description: {
                    Text("Add buckets to divide your income, then mark one as the Reserve.")
                } actions: {
                    Button("Browse starter envelopes") { sheet = .starter }
                        .accessibilityIdentifier(A11y.Starter.browse)
                    Button("Create one manually") { sheet = .add }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add envelope", systemImage: "plus") { sheet = .add }
                    Button("Browse starter envelopes", systemImage: "square.grid.2x2") { sheet = .starter }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(item: $sheet) { route in
            switch route {
            case .add:
                AddEnvelopeScreen(onSave: store.add)
            case .edit(let envelope):
                AddEnvelopeScreen(editing: envelope, onSave: store.update)
            case .starter:
                StarterEnvelopesSheet(store: store)
            }
        }
    }
}
