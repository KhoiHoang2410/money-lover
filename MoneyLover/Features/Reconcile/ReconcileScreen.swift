import SwiftUI

/// Reconcile ("update balance"): the owner re-enters each source's real balance and any
/// drift is recorded as an Adjustment carrying a note and an Envelope. Pushed from
/// Config → Update balances, so it carries no `NavigationStack` of its own.
struct ReconcileScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var store: ReconcileStore?
    @State private var realBalances: [UUID: Decimal] = [:]
    @State private var envelopeID: UUID?
    @State private var note = ""

    var body: some View {
        Group {
            if let store {
                content(store)
            } else {
                ProgressView()
                    .task {
                        guard store == nil else { return }
                        let newStore = ReconcileStore(
                            sources: SourceRepository(context: context),
                            transactions: TransactionRepository(context: context),
                            envelopes: EnvelopeRepository(context: context)
                        )
                        newStore.load()
                        seed(from: newStore)
                        store = newStore
                    }
            }
        }
        .navigationTitle("Update balances")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ store: ReconcileStore) -> some View {
        Form {
            Section {
                ForEach(store.sources) { source in
                    ReconcileRow(
                        source: source,
                        computed: store.computedBalance(for: source),
                        realBalance: binding(for: source)
                    )
                }
            } footer: {
                Text("Enter the real balance shown by each bank or wallet. Any difference is logged as an Adjustment so the Current balance always matches reality.")
            }

            if !pendingAdjustments(store).isEmpty {
                Section("Explain the adjustment") {
                    Picker("Envelope", selection: $envelopeID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.envelopes) { envelope in
                            Text(envelope.name).tag(Optional(envelope.id))
                        }
                    }
                    .accessibilityIdentifier(A11y.Reconcile.envelope)
                    TextField("Note (e.g. forgotten cash spends)", text: $note, axis: .vertical)
                        .accessibilityIdentifier(A11y.Reconcile.note)
                }
            }
        }
        .overlay {
            if store.sources.isEmpty {
                ContentUnavailableView(
                    "No sources to reconcile",
                    systemImage: "creditcard",
                    description: Text("Create an account or card in Config → Sources.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Record") { record(store) }
                    .disabled(pendingAdjustments(store).isEmpty)
                    .accessibilityIdentifier(A11y.Reconcile.record)
            }
        }
    }

    private func binding(for source: Source) -> Binding<Decimal> {
        Binding(
            get: { realBalances[source.id] ?? source.openingBalance.amount },
            set: { realBalances[source.id] = $0 }
        )
    }

    private func seed(from store: ReconcileStore) {
        for source in store.sources {
            realBalances[source.id] = store.computedBalance(for: source).amount
        }
    }

    private func pendingAdjustments(_ store: ReconcileStore) -> [Transaction] {
        store.sources.compactMap { source in
            let entered = Money(major: realBalances[source.id] ?? 0, currency: source.currency)
            return store.adjustment(for: source, realBalance: entered, envelopeID: envelopeID, note: note)
        }
    }

    private func record(_ store: ReconcileStore) {
        store.record(pendingAdjustments(store))
        seed(from: store)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ReconcileScreen()
            .modelContainer(for: AppSchema.models, inMemory: true)
    }
}
