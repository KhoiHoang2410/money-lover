import SwiftUI

/// Lists envelopes with spent/remaining, swipe-to-set-Reserve, and an add button.
struct EnvelopesList: View {
    let store: EnvelopesStore
    @State private var showingAdd = false
    @State private var showingStarter = false

    var body: some View {
        List {
            ForEach(store.envelopes) { envelope in
                EnvelopeRow(
                    envelope: envelope,
                    spent: store.spent(for: envelope),
                    remaining: store.remaining(for: envelope)
                )
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
                    Button("Browse starter envelopes") { showingStarter = true }
                        .accessibilityIdentifier(A11y.Starter.browse)
                    Button("Create one manually") { showingAdd = true }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add envelope", systemImage: "plus") { showingAdd = true }
                    Button("Browse starter envelopes", systemImage: "square.grid.2x2") { showingStarter = true }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddEnvelopeScreen(onSave: store.add)
        }
        .sheet(isPresented: $showingStarter) {
            StarterEnvelopesSheet(store: store)
        }
    }
}
