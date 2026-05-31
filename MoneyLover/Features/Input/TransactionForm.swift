import SwiftUI

/// One merged entry form for the three everyday Transaction kinds, switched by a segmented **Type**
/// control (Expense default / Income / Transfer). The amount auto-focuses the number pad on open;
/// only the note uses the normal (alphabet) keyboard. Transfer keeps its full power — same-currency,
/// cross-currency (manual Rate + computed Fee), and pay-card — under a secondary **Method** switch.
struct TransactionForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss

    private enum Field: Hashable { case amount, amountIn, rate, note }
    @FocusState private var focus: Field?

    @State private var kind: TransactionKind = .expense

    // Shared
    @State private var amountMajor: Decimal = 0
    @State private var note = ""

    // Expense / Income
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?

    // Transfer
    @State private var method: TransferMode = .sameCurrency
    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var amountInMajor: Decimal = 0
    @State private var rate: Decimal = 0

    var body: some View {
        Form {
            Picker("Type", selection: $kind) {
                Text("Expense").tag(TransactionKind.expense)
                Text("Income").tag(TransactionKind.income)
                Text("Transfer").tag(TransactionKind.transfer)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11y.Txn.typePicker)

            switch kind {
            case .expense: expenseFields
            case .income: incomeFields
            case .transfer: transferFields
            case .adjustment: EmptyView() // Adjustments are created by Reconcile, not offered here.
            }
        }
        .navigationTitle("Add transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
                    .accessibilityIdentifier(A11y.Txn.save)
            }
        }
        .onAppear { focus = .amount }
    }

    // MARK: - Field groups

    @ViewBuilder
    private var expenseFields: some View {
        Section { decimalField("Amount", $amountMajor, focus: .amount, id: A11y.Txn.amount) }
        Section {
            Picker("From", selection: $sourceID) {
                Text("Select…").tag(UUID?.none)
                ForEach(store.sources) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            Picker("Envelope", selection: $envelopeID) {
                Text("None").tag(UUID?.none)
                ForEach(store.envelopes) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.envelope)
        }
        noteSection
        if let nudge {
            Section {
                SignalCard(signal: nudge)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }

    @ViewBuilder
    private var incomeFields: some View {
        Section { decimalField("Amount", $amountMajor, focus: .amount, id: A11y.Txn.amount) }
        Section {
            Picker("Into", selection: $sourceID) {
                Text("Select…").tag(UUID?.none)
                ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
        }
        noteSection
    }

    @ViewBuilder
    private var transferFields: some View {
        Picker("Method", selection: $method) {
            ForEach(TransferMode.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
        .accessibilityIdentifier(A11y.Txn.method)

        Section {
            Picker("From", selection: $fromID) {
                Text("Select…").tag(UUID?.none)
                ForEach(fromOptions) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            Picker("To", selection: $toID) {
                Text("Select…").tag(UUID?.none)
                ForEach(toOptions) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.destination)
        }
        Section {
            decimalField(method == .crossCurrency ? "Amount out" : "Amount", $amountMajor, focus: .amount, id: A11y.Txn.amount)
            if method == .crossCurrency {
                decimalField("Amount in", $amountInMajor, focus: .amountIn, id: A11y.Txn.amountIn)
                decimalField("Rate", $rate, focus: .rate, id: A11y.Txn.rate)
                if let fee = computedFee {
                    LabeledContent("Fee") {
                        Text(fee.amount, format: .currency(code: fee.currency.rawValue))
                            .foregroundStyle(Theme.Palette.pinkDeep)
                    }
                }
            }
        }
    }

    private var noteSection: some View {
        Section {
            TextField("Note", text: $note, axis: .vertical)
                .focused($focus, equals: .note)
                .accessibilityIdentifier(A11y.Txn.note)
        }
    }

    private func decimalField(_ title: String, _ value: Binding<Decimal>, focus field: Field, id: String) -> some View {
        LabeledContent(title) {
            TextField(title, value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: field)
                .accessibilityIdentifier(id)
        }
    }

    // MARK: - Options

    private var accounts: [Source] { store.sources.filter { $0.kind == .account } }

    private var fromOptions: [Source] {
        method == .payCard ? store.sources.filter { $0.kind == .account } : store.sources
    }

    private var toOptions: [Source] {
        switch method {
        case .payCard: store.sources.filter { $0.kind == .creditCard }
        default: store.sources.filter { $0.id != fromID }
        }
    }

    private var fromSource: Source? { store.sources.first { $0.id == fromID } }
    private var toSource: Source? { store.sources.first { $0.id == toID } }

    /// The charged/credited source for an Expense (any source) or Income (an Account).
    private var selectedSource: Source? {
        kind == .income ? accounts.first { $0.id == sourceID } : store.sources.first { $0.id == sourceID }
    }

    private var computedFee: Money? {
        guard method == .crossCurrency, let from = fromSource, let to = toSource, rate > 0 else { return nil }
        return TransferEngine.fee(
            amountOut: Money(major: amountMajor, currency: from.currency),
            amountIn: Money(major: amountInMajor, currency: to.currency),
            rate: rate
        )
    }

    /// A live warning when an Expense would outpace or overspend the selected envelope.
    /// Envelopes are budgeted in the base currency (VND); the form has no rates to convert a
    /// foreign-currency expense, so the nudge is shown only for VND sources rather than comparing
    /// a foreign magnitude against a VND allocation (BUG-005).
    private var nudge: Signal? {
        guard kind == .expense, amountMajor > 0,
              let source = selectedSource, source.currency == .vnd,
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

    // MARK: - Save

    private var canSave: Bool {
        switch kind {
        case .expense, .income:
            return selectedSource != nil && amountMajor > 0
        case .transfer:
            guard let from = fromSource, let to = toSource, from.id != to.id, amountMajor > 0 else { return false }
            return method != .crossCurrency || (amountInMajor > 0 && rate > 0)
        case .adjustment:
            return false
        }
    }

    private func save() {
        switch kind {
        case .expense:
            guard let source = selectedSource else { return }
            store.add(Transaction(
                kind: .expense,
                amount: Money(major: amountMajor, currency: source.currency),
                sourceID: source.id,
                note: note,
                envelopeID: envelopeID
            ))
        case .income:
            guard let source = selectedSource else { return }
            store.add(Transaction(
                kind: .income,
                amount: Money(major: amountMajor, currency: source.currency),
                sourceID: source.id,
                note: note
            ))
        case .transfer:
            guard let from = fromSource, let to = toSource else { return }
            let out = Money(major: amountMajor, currency: from.currency)
            if method == .crossCurrency {
                let received = Money(major: amountInMajor, currency: to.currency)
                store.add(Transaction(
                    kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                    destinationAmount: received,
                    fee: TransferEngine.fee(amountOut: out, amountIn: received, rate: rate),
                    note: "Transfer"
                ))
            } else {
                store.add(Transaction(
                    kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                    note: method == .payCard ? "Card payment" : "Transfer"
                ))
            }
        case .adjustment:
            return
        }
        dismiss()
    }
}
