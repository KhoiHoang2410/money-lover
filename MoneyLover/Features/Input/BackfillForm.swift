import SwiftUI

/// Backfill: log a forgotten *past* expense or income as an informational entry
/// (`affectsBalance == false`). It shows up in history and day-detail but never moves the
/// Current balance — which is already correct.
struct BackfillForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss
    @State private var kind: TransactionKind = .expense
    @State private var amountMajor: Decimal = 0
    @State private var date = Date.now
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?
    @State private var note = ""

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $kind) {
                    Text("Expense").tag(TransactionKind.expense)
                    Text("Income").tag(TransactionKind.income)
                }
                .pickerStyle(.segmented)
            }
            Section {
                LabeledContent("Amount") {
                    TextField("Amount", value: $amountMajor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
            }
            Section {
                Picker(kind == .income ? "Into" : "From", selection: $sourceID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(selectableSources) { source in
                        Text(source.name).tag(Optional(source.id))
                    }
                }
                if kind == .expense {
                    Picker("Envelope", selection: $envelopeID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.envelopes) { envelope in
                            Text(envelope.name).tag(Optional(envelope.id))
                        }
                    }
                }
            }
            Section {
                TextField("Note", text: $note, axis: .vertical)
            } footer: {
                Text("Backfill is informational only — it appears in history but does not change your Current balance.")
            }
        }
        .navigationTitle("Backfill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }

    private var selectableSources: [Source] {
        kind == .income ? store.sources.filter { $0.kind == .account } : store.sources
    }

    private var selectedSource: Source? {
        selectableSources.first { $0.id == sourceID }
    }

    private var canSave: Bool {
        selectedSource != nil && amountMajor > 0
    }

    private func save() {
        guard let source = selectedSource else { return }
        let transaction = Transaction(
            date: date,
            kind: kind,
            amount: Money(major: amountMajor, currency: source.currency),
            sourceID: source.id,
            note: note,
            envelopeID: kind == .expense ? envelopeID : nil,
            affectsBalance: false
        )
        store.add(transaction)
        dismiss()
    }
}
