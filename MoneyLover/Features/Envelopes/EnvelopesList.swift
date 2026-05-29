import SwiftUI

/// Lists envelopes with spent/remaining, swipe-to-set-Reserve, and an add button.
struct EnvelopesList: View {
    let store: EnvelopesStore
    @State private var showingAdd = false

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
                ContentUnavailableView(
                    "No envelopes",
                    systemImage: "tray.full",
                    description: Text("Add buckets to divide your income, then mark one as the Reserve.")
                )
            }
        }
        .toolbar {
            Button("Add envelope", systemImage: "plus") { showingAdd = true }
        }
        .sheet(isPresented: $showingAdd) {
            AddEnvelopeScreen(onSave: store.add)
        }
    }
}
