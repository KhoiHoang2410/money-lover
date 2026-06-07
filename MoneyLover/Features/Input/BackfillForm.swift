import SwiftUI

/// Backfill: log a forgotten *past* expense or income as an informational entry
/// (`affectsBalance == false`). It shows up in history and day-detail but never moves the
/// Current balance — which is already correct.
struct BackfillForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss

    // Remembered last-picked options, shared with the Add-transaction form (feat 2).
    @AppStorage("txn.default.expenseSource") private var defaultExpenseSource = ""
    @AppStorage("txn.default.incomeSource") private var defaultIncomeSource = ""
    @AppStorage("txn.default.envelope") private var defaultEnvelope = ""

    private enum Field: Hashable { case amount, note }
    @FocusState private var focus: Field?

    @State private var kind: TransactionKind = .expense
    @State private var amountMajor: Decimal = 0
    @State private var amountText = ""
    @State private var date = Date.now
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?
    @State private var note = ""
    @State private var loaded = false

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
                // Same live thousands-grouping field as the Add-transaction form, so a backfilled
                // amount shows "1,000,000" while typing instead of the raw digits (feat 4).
                amountField
                DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
            }
            Section {
                Picker(kind == .income ? "Into" : "From", selection: $sourceID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(selectableSources) { source in
                        SourcePickerLabel(source: source).tag(Optional(source.id))
                    }
                }
                .accessibilityIdentifier(A11y.Txn.source)
                if kind == .expense {
                    Picker("Envelope", selection: $envelopeID) {
                        Text("None").tag(UUID?.none)
                        ForEach(store.envelopes) { envelope in
                            EnvelopePickerLabel(envelope: envelope).tag(Optional(envelope.id))
                        }
                    }
                    .accessibilityIdentifier(A11y.Txn.envelope)
                }
            }
            Section {
                TextField("Note", text: $note, axis: .vertical)
                    .focused($focus, equals: .note)
                    .accessibilityIdentifier(A11y.Txn.note)
            } footer: {
                Text("Backfill is informational only — it appears in history but does not change your Current balance.")
            }
        }
        .navigationTitle("Backfill")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
                    .accessibilityIdentifier(A11y.Txn.save)
            }
        }
        .keyboardDoneButton()
        .onAppear(perform: applyDefaultsIfNeeded)
        .onChange(of: kind) { _, _ in applyDefaults() }
    }

    /// A money field that groups thousands live as the user types, keeping the bound `Decimal` exact
    /// (see `AmountInputFormatter` / `TransactionForm.amountField`).
    private var amountField: some View {
        let formatter = AmountInputFormatter(maximumFractionDigits: 2)
        return LabeledContent("Amount") {
            TextField("Amount", text: $amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: .amount)
                .accessibilityIdentifier(A11y.Txn.amount)
                .onChange(of: amountText) { _, newValue in
                    let formatted = formatter.format(newValue)
                    if formatted != newValue { amountText = formatted }
                    amountMajor = formatter.value(formatted)
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

    // MARK: - Remembered defaults (feat 2)

    private func applyDefaultsIfNeeded() {
        guard !loaded else { return }
        loaded = true
        applyDefaults()
    }

    private func applyDefaults() {
        switch kind {
        case .income:
            if let id = storedID(defaultIncomeSource, in: selectableSources) { sourceID = id }
        default:
            if let id = storedID(defaultExpenseSource, in: selectableSources) { sourceID = id }
            if let id = storedID(defaultEnvelope, in: store.envelopes) { envelopeID = id }
        }
    }

    private func rememberDefaults() {
        if kind == .income {
            if let sourceID { defaultIncomeSource = sourceID.uuidString }
        } else {
            if let sourceID { defaultExpenseSource = sourceID.uuidString }
            defaultEnvelope = envelopeID?.uuidString ?? ""
        }
    }

    private func storedID(_ stored: String, in options: [some Identifiable<UUID>]) -> UUID? {
        guard let id = UUID(uuidString: stored), options.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    private func save() {
        guard let source = selectedSource else { return }
        rememberDefaults()
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
