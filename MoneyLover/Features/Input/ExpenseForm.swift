import SwiftUI

/// Manual expense entry: amount, the source charged, and a note.
struct ExpenseForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss
    @State private var amountMajor: Decimal = 0
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?
    @State private var note = ""

    var body: some View {
        Form {
            Section {
                LabeledContent("Amount") {
                    TextField("Amount", value: $amountMajor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section {
                Picker("From", selection: $sourceID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(store.sources) { source in
                        Text(source.name).tag(Optional(source.id))
                    }
                }
                Picker("Envelope", selection: $envelopeID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.envelopes) { envelope in
                        Text(envelope.name).tag(Optional(envelope.id))
                    }
                }
            }
            Section {
                TextField("Note", text: $note, axis: .vertical)
            }
            if let nudge {
                Section {
                    SignalCard(signal: nudge)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
        }
        .navigationTitle("Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }

    private var selectedSource: Source? {
        store.sources.first { $0.id == sourceID }
    }

    private var canSave: Bool {
        selectedSource != nil && amountMajor > 0
    }

    /// A live warning when the chosen amount would outpace or overspend the selected envelope.
    private var nudge: Signal? {
        guard amountMajor > 0,
              let envelopeID,
              let envelope = store.envelopes.first(where: { $0.id == envelopeID })
        else { return nil }
        return SignalEngine.envelopeNudge(
            envelope: envelope,
            transactions: store.transactions,
            adding: Money(major: amountMajor, currency: .vnd),
            asOf: .now
        )
    }

    private func save() {
        guard let source = selectedSource else { return }
        let transaction = Transaction(
            kind: .expense,
            amount: Money(major: amountMajor, currency: source.currency),
            sourceID: source.id,
            note: note,
            envelopeID: envelopeID
        )
        store.add(transaction)
        dismiss()
    }
}
