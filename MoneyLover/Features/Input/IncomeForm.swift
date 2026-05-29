import SwiftUI

/// Manual income entry: amount received into an Account, with a note.
struct IncomeForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss
    @State private var amountMajor: Decimal = 0
    @State private var sourceID: UUID?
    @State private var note = ""

    private var accounts: [Source] {
        store.sources.filter { $0.kind == .account }
    }

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
                Picker("Into", selection: $sourceID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(accounts) { source in
                        Text(source.name).tag(Optional(source.id))
                    }
                }
            }
            Section {
                TextField("Note", text: $note, axis: .vertical)
            }
        }
        .navigationTitle("Income")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }

    private var selectedSource: Source? {
        accounts.first { $0.id == sourceID }
    }

    private var canSave: Bool {
        selectedSource != nil && amountMajor > 0
    }

    private func save() {
        guard let source = selectedSource else { return }
        let transaction = Transaction(
            kind: .income,
            amount: Money(major: amountMajor, currency: source.currency),
            sourceID: source.id,
            note: note
        )
        store.add(transaction)
        dismiss()
    }
}
