import SwiftUI

/// Lists envelopes with spent/remaining, tap-to-edit (adjust caps), swipe-to-set-Reserve, and add.
struct EnvelopesList: View {
    let store: EnvelopesStore
    @State private var sheet: EnvelopeSheetRoute?

    var body: some View {
        List {
            ForEach(store.envelopes) { envelope in
                // Tap-to-edit via onTapGesture (not Button) so we keep the List swipe action.
                // `.accessibilityElement(children: .combine)` collapses the row's icon / name /
                // spent / remaining / progress into ONE element (label = their text joined) carrying
                // the row identifier — the same single-element shape Overview's NavigationLink rows
                // get for free. Without it, putting `.accessibilityIdentifier` on the multi-child row
                // propagates that id onto every leaf, so each piece becomes a separate button sharing
                // `envelope.row.<name>` and the inner remaining id is clobbered (a UI test then can't
                // read the remaining, and the name surfaces as a button rather than static text).
                EnvelopeRow(
                    envelope: envelope,
                    spent: store.spent(for: envelope),
                    remaining: store.remaining(for: envelope),
                    weekSpent: store.weekSpent(for: envelope),
                    monthSpent: store.monthSpent(for: envelope)
                )
                .contentShape(Rectangle())
                .onTapGesture { sheet = .edit(envelope) }
                .accessibilityElement(children: .combine)
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
