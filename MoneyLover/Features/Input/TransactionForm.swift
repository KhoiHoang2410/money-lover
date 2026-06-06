import SwiftUI

/// One merged entry form for the three everyday Transaction kinds, switched by a segmented **Type**
/// control (Expense default / Income / Transfer). The amount auto-focuses the number pad on open;
/// only the note uses the normal (alphabet) keyboard. Transfer keeps its full power — same-currency,
/// cross-currency (manual Rate + computed Fee), and pay-card — under a secondary **Method** switch.
struct TransactionForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss

    private enum Field: Hashable { case amount, amountIn, rate, unitPrice, note }
    @FocusState private var focus: Field?

    @State private var kind: TransactionKind = .expense

    // Shared
    @State private var amountMajor: Decimal = 0
    @State private var amountText = ""
    @State private var note = ""

    // Expense / Income
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?

    // Transfer
    @State private var method: TransferMode = .sameCurrency
    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var amountInMajor: Decimal = 0
    @State private var amountInText = ""
    @State private var rate: Decimal = 0

    // Invest (Buy/Sell of a Holding) — ADR-0010
    @State private var direction: TradeDirection = .buy
    @State private var accountID: UUID?
    @State private var holdingID: UUID?
    @State private var quantity: Decimal = 0
    @State private var quantityText = ""
    @State private var unitPriceMajor: Decimal = 0
    @State private var unitPriceText = ""

    var body: some View {
        Form {
            Picker("Type", selection: $kind) {
                Text("Expense").tag(TransactionKind.expense)
                Text("Income").tag(TransactionKind.income)
                Text("Transfer").tag(TransactionKind.transfer)
                Text("Invest").tag(TransactionKind.invest)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11y.Txn.typePicker)

            switch kind {
            case .expense: expenseFields
            case .income: incomeFields
            case .transfer: transferFields
            case .invest: investFields
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
        Section { amountField("Amount", text: $amountText, value: $amountMajor, focus: .amount, id: A11y.Txn.amount) }
        Section {
            Picker("From", selection: $sourceID) {
                Text("Select…").tag(UUID?.none)
                ForEach(spendableSources) { Text($0.name).tag(Optional($0.id)) }
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
        Section { amountField("Amount", text: $amountText, value: $amountMajor, focus: .amount, id: A11y.Txn.amount) }
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
            amountField(method == .crossCurrency ? "Amount out" : "Amount", text: $amountText, value: $amountMajor, focus: .amount, id: A11y.Txn.amount)
            if method == .crossCurrency {
                amountField("Amount in", text: $amountInText, value: $amountInMajor, focus: .amountIn, id: A11y.Txn.amountIn)
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

    @ViewBuilder
    private var investFields: some View {
        Picker("Direction", selection: $direction) {
            ForEach(TradeDirection.allCases) { Text($0.title).tag($0) }
        }
        .pickerStyle(.segmented)
        .listRowBackground(Color.clear)
        .accessibilityIdentifier(A11y.Txn.tradeDirection)

        Section {
            Picker(direction == .buy ? "Pay from" : "Receive into", selection: $accountID) {
                Text("Select…").tag(UUID?.none)
                ForEach(vndAccounts) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            Picker("Holding", selection: $holdingID) {
                Text("Select…").tag(UUID?.none)
                ForEach(store.holdings) { Text($0.name).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.holding)
        }
        Section {
            LabeledContent("Quantity") {
                // Text-bound (not value:format:) so the parsed quantity updates live as typed —
                // the Save/oversell guard reacts before the field loses focus.
                TextField("Qty", text: $quantityText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .accessibilityIdentifier(A11y.Txn.quantity)
                    .onChange(of: quantityText) { _, newValue in
                        quantity = Decimal(string: newValue.replacingOccurrences(of: ",", with: ".")) ?? 0
                    }
            }
            amountField("Unit price (₫)", text: $unitPriceText, value: $unitPriceMajor, focus: .unitPrice, id: A11y.Txn.unitPrice)
            LabeledContent(direction == .buy ? "Total cost" : "Total proceeds") {
                Text(investTotal.amount, format: .currency(code: Currency.vnd.rawValue))
                    .foregroundStyle(Theme.Palette.ink)
            }
        }
        if let holdingID, direction == .sell {
            Section {
                LabeledContent("Currently held") {
                    Text(heldQuantity(holdingID), format: .number)
                        .foregroundStyle(quantity > heldQuantity(holdingID) ? Theme.Palette.bad : .secondary)
                }
            }
        }
        noteSection
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

    /// A money field that shows locale grouping separators live as the user types (e.g. "1,000,000"),
    /// keeping the bound `Decimal` exact. The source currency isn't known until a source is picked, so
    /// it allows up to 2 fraction digits (the max across currencies); `Money(major:)` rounds to the
    /// currency's grid at save.
    ///
    /// Re-grouping happens in `.onChange` (not inside the binding's setter): reformatting mid-keystroke
    /// from within the setter is dropped by SwiftUI's editing buffer, whereas onChange runs in the next
    /// update cycle so the regrouped string is reflected back into the field.
    private func amountField(_ title: String, text: Binding<String>, value: Binding<Decimal>, focus field: Field, id: String) -> some View {
        let formatter = AmountInputFormatter(maximumFractionDigits: 2)
        return LabeledContent(title) {
            TextField(title, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused($focus, equals: field)
                .accessibilityIdentifier(id)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let formatted = formatter.format(newValue)
                    if formatted != newValue { text.wrappedValue = formatted }
                    value.wrappedValue = formatter.value(formatted)
                }
        }
    }

    // MARK: - Options

    private var accounts: [Source] { store.sources.filter { $0.kind == .account } }

    /// Accounts and cards — the sources an Expense or Transfer can touch. Holdings are excluded;
    /// they only move via Invest (ADR-0010).
    private var spendableSources: [Source] { store.sources.filter { $0.kind != .holding } }

    /// VND Accounts are the only sources that can Buy/Sell a Holding (ADR-0010).
    private var vndAccounts: [Source] {
        store.sources.filter { $0.kind == .account && $0.currency == .vnd }
    }

    /// Money moved by the trade = quantity × unit price, in VND.
    private var investTotal: Money {
        Money(major: quantity * unitPriceMajor, currency: .vnd)
    }

    /// The Holding's current live quantity (opening ± prior trades), for the oversell guard.
    private func heldQuantity(_ id: UUID) -> Decimal {
        guard let holding = store.holdings.first(where: { $0.id == id }) else { return 0 }
        return HoldingQuantityEngine.liveQuantity(of: holding, transactions: store.transactions)
    }

    private var fromOptions: [Source] {
        method == .payCard ? store.sources.filter { $0.kind == .account } : spendableSources
    }

    private var toOptions: [Source] {
        switch method {
        case .payCard: store.sources.filter { $0.kind == .creditCard }
        default: spendableSources.filter { $0.id != fromID }
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
        case .invest:
            guard accountID != nil, let holdingID, quantity > 0, unitPriceMajor > 0 else { return false }
            // A Sell cannot exceed the units currently held (ADR-0010).
            return direction == .buy || quantity <= heldQuantity(holdingID)
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
        case .invest:
            guard let accountID, let holdingID else { return }
            let holdingName = store.holdings.first { $0.id == holdingID }?.name ?? "holding"
            store.add(Transaction(
                kind: .invest,
                amount: investTotal,
                sourceID: accountID,
                destinationID: holdingID,
                note: "\(direction.title) \(holdingName)",
                tradeQuantity: quantity,
                tradeDirection: direction
            ))
        case .adjustment:
            return
        }
        dismiss()
    }
}
