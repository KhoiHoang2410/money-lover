import SwiftUI

/// One merged entry form for the three everyday Transaction kinds, switched by a segmented **Type**
/// control (Expense default / Income / Transfer). The amount auto-focuses the number pad on open;
/// only the note uses the normal (alphabet) keyboard. Transfer keeps its full power — same-currency,
/// cross-currency (manual Rate + computed Fee), and pay-card — under a secondary **Method** switch.
struct TransactionForm: View {
    let store: InputStore
    /// When set, the form edits this transaction in place (Save updates, keeps its id). Nil = add.
    var editing: Transaction?
    /// The date to prefill a *new* transaction with (e.g. the day picked on the Calendar). Ignored
    /// when editing — the edited transaction keeps/overrides its own date.
    var initialDate: Date?
    /// When editing, an optional action to delete the transaction (feat 5). Shown as a Delete button.
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @AppStorage("confirmBeforeDelete") private var confirmBeforeDelete = false

    // Remembered last-picked options, reused as defaults for the next *new* transaction (feat 2).
    // Stored as UUID strings; an empty string means "none remembered yet".
    @AppStorage("txn.default.expenseSource") private var defaultExpenseSource = ""
    @AppStorage("txn.default.incomeSource") private var defaultIncomeSource = ""
    @AppStorage("txn.default.envelope") private var defaultEnvelope = ""
    @AppStorage("txn.default.transferFrom") private var defaultTransferFrom = ""
    @AppStorage("txn.default.transferTo") private var defaultTransferTo = ""
    @AppStorage("txn.default.investAccount") private var defaultInvestAccount = ""
    /// Whether the Backfilled toggle was last left on — remembered for the next new Expense/Income.
    @AppStorage("txn.default.backfilled") private var defaultBackfilled = false

    private enum Field: Hashable { case amount, amountIn, rate, unitPrice, note }
    @FocusState private var focus: Field?

    @State private var kind: TransactionKind = .expense
    @State private var date = Date.now
    @State private var loaded = false
    @State private var confirmingDelete = false

    // Shared
    @State private var amountMajor: Decimal = 0
    @State private var note = ""

    // Expense / Income
    @State private var sourceID: UUID?
    @State private var envelopeID: UUID?
    /// Marks a new Expense/Income as a Backfill — a forgotten past entry recorded normally but with
    /// an offsetting opening-balance restatement so the current balance stays put (ADR-0012).
    @State private var backfilled = false

    // Transfer
    @State private var method: TransferMode = .sameCurrency
    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var amountInMajor: Decimal = 0
    @State private var rate: Decimal = 0

    // Invest (Buy/Sell of a Holding) — ADR-0010
    @State private var direction: TradeDirection = .buy
    @State private var accountID: UUID?
    @State private var holdingID: UUID?
    @State private var quantity: Decimal = 0
    @State private var unitPriceMajor: Decimal = 0

    var body: some View {
        Form {
            if isAdjustment {
                adjustmentSummary
            } else if isGoalContribution {
                goalContributionSummary
            } else {
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

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier(A11y.Txn.date)
                }
            }

            if editing != nil, onDelete != nil, !isGoalContribution {
                Section {
                    Button("Delete transaction", role: .destructive) {
                        if confirmBeforeDelete { confirmingDelete = true } else { performDelete() }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier(A11y.Txn.delete)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isAdjustment, !isGoalContribution {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                        .accessibilityIdentifier(A11y.Txn.save)
                }
            }
        }
        .keyboardDoneButton()
        .onAppear {
            loadIfNeeded()
            if editing == nil { focus = .amount }
        }
        .onChange(of: kind) { _, newKind in
            // Re-apply the remembered default for the kind the user just switched to, but never
            // overwrite an edited transaction's own values.
            if editing == nil { applyDefaults(for: newKind) }
        }
        .alert("Delete this transaction?", isPresented: $confirmingDelete) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes it and updates your balances.")
        }
    }

    private func performDelete() {
        onDelete?()
        dismiss()
    }

    /// Editing a Reconcile Adjustment: it's shown read-only (the everyday form can't represent a
    /// signed balance-fix), but it can still be deleted from here (feat).
    private var isAdjustment: Bool { editing?.kind == .adjustment }

    /// Editing a Goal contribution: a `.transfer` carrying a `goalID` (ADR-0007). Shown read-only —
    /// the everyday form can't represent it, and contributions have no undo here (it would also
    /// silently drop the `goalID` on save, since the Calendar lists it by date like any entry).
    private var isGoalContribution: Bool { editing?.kind == .transfer && editing?.goalID != nil }

    private var navigationTitle: String {
        if isAdjustment { return "Adjustment" }
        if isGoalContribution { return "Goal contribution" }
        return editing == nil ? "Add transaction" : "Edit transaction"
    }

    // MARK: - Field groups

    /// Read-only summary of a balance Adjustment, plus context that it came from Update balances.
    @ViewBuilder
    private var adjustmentSummary: some View {
        if let adjustment = editing {
            Section {
                LabeledContent("Amount") {
                    Text(adjustment.amount.amount, format: .currency(code: adjustment.amount.currency.rawValue))
                        .foregroundStyle(adjustment.amount.isNegative ? Theme.Palette.bad : Theme.Palette.ok)
                }
                if !adjustment.note.isEmpty {
                    LabeledContent("Note") { Text(adjustment.note) }
                }
                LabeledContent("Date") {
                    Text(adjustment.date, format: .dateTime.day().month().year())
                }
            } footer: {
                Text("A balance Adjustment recorded by Update balances. It can't be edited here — delete it to remove its effect on the balance.")
            }
        }
    }

    /// Read-only summary of a Goal contribution (a `.transfer` to a Goal). It can be viewed but not
    /// edited or undone from here (ADR-0007).
    @ViewBuilder
    private var goalContributionSummary: some View {
        if let contribution = editing {
            Section {
                LabeledContent("Amount") {
                    Text(contribution.amount.amount, format: .currency(code: contribution.amount.currency.rawValue))
                        .foregroundStyle(Theme.Palette.ink)
                }
                if let goalName = store.goals.first(where: { $0.id == contribution.goalID })?.name {
                    LabeledContent("Goal") { Text(goalName) }
                }
                if let fromName = store.sources.first(where: { $0.id == contribution.sourceID })?.name {
                    LabeledContent("From") { Text(fromName) }
                }
                if !contribution.note.isEmpty {
                    LabeledContent("Note") { Text(contribution.note) }
                }
                LabeledContent("Date") {
                    Text(contribution.date, format: .dateTime.day().month().year())
                }
            } footer: {
                Text("A contribution to a goal. It can't be edited or undone here.")
            }
        }
    }

    @ViewBuilder
    private var expenseFields: some View {
        Section { amountRow("Amount", value: $amountMajor, focus: .amount, id: A11y.Txn.amount) }
        Section {
            Picker("From", selection: $sourceID) {
                Text("Select…").tag(UUID?.none)
                ForEach(spendableSources) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            Picker("Envelope", selection: $envelopeID) {
                Text("None").tag(UUID?.none)
                ForEach(store.envelopes) { EnvelopePickerLabel(envelope: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.envelope)
        }
        noteSection
        backfillToggle
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
        Section { amountRow("Amount", value: $amountMajor, focus: .amount, id: A11y.Txn.amount) }
        Section {
            Picker("Into", selection: $sourceID) {
                Text("Select…").tag(UUID?.none)
                ForEach(accounts) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
        }
        noteSection
        backfillToggle
    }

    /// Offered only when adding (not editing): mark a forgotten past Expense/Income as a Backfill.
    @ViewBuilder
    private var backfillToggle: some View {
        if editing == nil {
            Section {
                Toggle("Backfilled", isOn: $backfilled)
                    .accessibilityIdentifier(A11y.Txn.backfilled)
            } footer: {
                Text("A forgotten past entry. It's recorded like a normal transaction and shows on the calendar; your opening balance is restated so your current balance doesn't change.")
            }
        }
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
                ForEach(fromOptions) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            if method == .goal {
                // "To" is a Goal, not a Source — a contribution funds the Goal directly (ADR-0007).
                Picker("To", selection: $toID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(store.goals) { goal in
                        Label(goal.name, systemImage: goal.iconName).tag(Optional(goal.id))
                    }
                }
                .accessibilityIdentifier(A11y.Txn.destination)
            } else {
                Picker("To", selection: $toID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(toOptions) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
                }
                .accessibilityIdentifier(A11y.Txn.destination)
            }
        }
        Section {
            amountRow(method == .crossCurrency ? "Amount out" : "Amount", value: $amountMajor, focus: .amount, id: A11y.Txn.amount)
            if method == .crossCurrency {
                amountRow("Amount in", value: $amountInMajor, focus: .amountIn, id: A11y.Txn.amountIn)
                amountRow("Rate", value: $rate, fractionDigits: 6, focus: .rate, id: A11y.Txn.rate)
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
                ForEach(vndAccounts) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.source)
            Picker("Holding", selection: $holdingID) {
                Text("Select…").tag(UUID?.none)
                ForEach(store.holdings) { SourcePickerLabel(source: $0).tag(Optional($0.id)) }
            }
            .accessibilityIdentifier(A11y.Txn.holding)
        }
        Section {
            LabeledContent("Quantity") {
                // Grouped + parsed live (the Save/oversell guard reacts before the field loses focus);
                // up to 4 fraction digits for fractional gold weights (chỉ/lượng).
                AmountField("Qty", value: $quantity, fractionDigits: 4, accessibilityID: A11y.Txn.quantity)
            }
            amountRow("Unit price (₫)", value: $unitPriceMajor, focus: .unitPrice, id: A11y.Txn.unitPrice)
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

    /// A labelled numeric row backed by the shared `AmountField` (live grouping, exact `Decimal`).
    /// The source currency isn't known until a source is picked, so amounts allow up to 2 fraction
    /// digits (the max across currencies); `Money(major:)` rounds to the currency's grid at save.
    private func amountRow(_ title: LocalizedStringKey, value: Binding<Decimal>, fractionDigits: Int = 2, focus field: Field, id: String) -> some View {
        LabeledContent(title) {
            AmountField(title, value: value, fractionDigits: fractionDigits, accessibilityID: id, focusState: $focus, focusTag: field)
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
        switch method {
        case .payCard: store.sources.filter { $0.kind == .account }
        // Only VND Accounts can fund a Goal (ADR-0007 — foreign-currency Accounts are excluded).
        case .goal: vndAccounts
        default: spendableSources
        }
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
            if method == .goal {
                // "To" holds the chosen Goal's id (not a Source); needs a funding Account + amount.
                return fromSource != nil && toID != nil && amountMajor > 0
            }
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
        rememberDefaults()
        // Editing keeps the original id; a new entry gets a fresh id.
        let id = editing?.id ?? UUID()

        switch kind {
        case .expense:
            guard let source = selectedSource else { return }
            persist(Transaction(
                id: id, date: date, kind: .expense,
                amount: Money(major: amountMajor, currency: source.currency),
                sourceID: source.id, note: note, envelopeID: envelopeID
            ), backfillSource: backfillSource(source))
        case .income:
            guard let source = selectedSource else { return }
            persist(Transaction(
                id: id, date: date, kind: .income,
                amount: Money(major: amountMajor, currency: source.currency),
                sourceID: source.id, note: note
            ), backfillSource: backfillSource(source))
        case .transfer:
            guard let from = fromSource else { return }
            if method == .goal {
                // A Goal contribution: a one-way `.transfer` from a VND Account to the Goal, with no
                // destination Source (ADR-0007). There's no undo for this in the form.
                guard let goalID = toID else { return }
                let goalName = store.goals.first { $0.id == goalID }?.name ?? "goal"
                persist(Transaction(
                    id: id, date: date, kind: .transfer,
                    amount: Money(major: amountMajor, currency: from.currency),
                    sourceID: from.id,
                    note: note.isEmpty ? "→ \(goalName)" : note,
                    goalID: goalID
                ))
                return
            }
            guard let to = toSource else { return }
            let out = Money(major: amountMajor, currency: from.currency)
            if method == .crossCurrency {
                let received = Money(major: amountInMajor, currency: to.currency)
                persist(Transaction(
                    id: id, date: date, kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                    destinationAmount: received,
                    fee: TransferEngine.fee(amountOut: out, amountIn: received, rate: rate),
                    note: note.isEmpty ? "Transfer" : note
                ))
            } else {
                persist(Transaction(
                    id: id, date: date, kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                    note: note.isEmpty ? (method == .payCard ? "Card payment" : "Transfer") : note
                ))
            }
        case .invest:
            guard let accountID, let holdingID else { return }
            let holdingName = store.holdings.first { $0.id == holdingID }?.name ?? "holding"
            persist(Transaction(
                id: id, date: date, kind: .invest,
                amount: investTotal, sourceID: accountID, destinationID: holdingID,
                note: note.isEmpty ? "\(direction.title) \(holdingName)" : note,
                tradeQuantity: quantity, tradeDirection: direction
            ))
        case .adjustment:
            return
        }
    }

    /// The source to restate when saving — non-nil only for a *new* Expense/Income marked Backfilled.
    private func backfillSource(_ source: Source) -> Source? {
        editing == nil && backfilled ? source : nil
    }

    /// Add a new transaction (compensating the opening balance when it's a Backfill) or update the
    /// edited one, then dismiss.
    private func persist(_ transaction: Transaction, backfillSource: Source? = nil) {
        if let backfillSource {
            store.addBackfill(transaction, source: backfillSource)
        } else if editing == nil {
            store.add(transaction)
        } else {
            store.update(transaction)
        }
        dismiss()
    }

    // MARK: - Remembered defaults (feat 2)

    /// Prefill the source/envelope pickers for a *new* transaction from the last-picked option for
    /// that kind, but only when the remembered id still exists in the current data.
    private func applyDefaults(for kind: TransactionKind) {
        // The Backfilled toggle only applies to Expense/Income; restore its last state there.
        backfilled = (kind == .expense || kind == .income) && defaultBackfilled
        switch kind {
        case .expense:
            if let id = storedID(defaultExpenseSource, in: spendableSources) { sourceID = id }
            if let id = storedID(defaultEnvelope, in: store.envelopes) { envelopeID = id }
        case .income:
            if let id = storedID(defaultIncomeSource, in: accounts) { sourceID = id }
        case .transfer:
            if let id = storedID(defaultTransferFrom, in: fromOptions) { fromID = id }
            if let id = storedID(defaultTransferTo, in: spendableSources), id != fromID { toID = id }
        case .invest:
            if let id = storedID(defaultInvestAccount, in: vndAccounts) { accountID = id }
        case .adjustment:
            break
        }
    }

    /// Record the options the user actually committed as the defaults for the next new transaction.
    private func rememberDefaults() {
        // Remember the Backfilled choice for the next new Expense/Income (it's hidden when editing).
        if editing == nil, kind == .expense || kind == .income { defaultBackfilled = backfilled }
        switch kind {
        case .expense:
            if let sourceID { defaultExpenseSource = sourceID.uuidString }
            defaultEnvelope = envelopeID?.uuidString ?? ""
        case .income:
            if let sourceID { defaultIncomeSource = sourceID.uuidString }
        case .transfer:
            if let fromID { defaultTransferFrom = fromID.uuidString }
            // In Goal mode `toID` is a Goal id, not a Source — don't store it as a transfer default.
            if method != .goal, let toID { defaultTransferTo = toID.uuidString }
        case .invest:
            if let accountID { defaultInvestAccount = accountID.uuidString }
        case .adjustment:
            break
        }
    }

    /// Resolve a stored UUID string to an id that still exists in `options`, else nil.
    private func storedID(_ stored: String, in options: [some Identifiable<UUID>]) -> UUID? {
        guard let id = UUID(uuidString: stored), options.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    // MARK: - Load (edit mode / date prefill)

    /// Populates the form once: from the edited transaction, or just the prefilled date for a new one.
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let t = editing else {
            if let initialDate { date = initialDate }
            applyDefaults(for: kind)
            return
        }
        // A Goal contribution renders read-only (goalContributionSummary) — no fields to populate.
        if t.kind == .transfer, t.goalID != nil { return }
        kind = t.kind
        date = t.date
        note = t.note
        // The numeric fields seed their own display from these `Decimal`s (AmountField.onChange(of:)).
        switch t.kind {
        case .expense:
            amountMajor = t.amount.amount
            sourceID = t.sourceID; envelopeID = t.envelopeID
        case .income:
            amountMajor = t.amount.amount
            sourceID = t.sourceID
        case .transfer:
            amountMajor = t.amount.amount
            fromID = t.sourceID; toID = t.destinationID
            if let received = t.destinationAmount {
                method = .crossCurrency
                amountInMajor = received.amount
                // Rate isn't stored; recover it from amounts + fee: fee = out×rate − in ⇒ rate = (in+fee)/out.
                let feeAmount = t.fee?.amount ?? 0
                rate = amountMajor == 0 ? 0 : (received.amount + feeAmount) / amountMajor
            } else if store.sources.first(where: { $0.id == t.destinationID })?.kind == .creditCard {
                method = .payCard
            } else {
                method = .sameCurrency
            }
        case .invest:
            direction = t.tradeDirection ?? .buy
            accountID = t.sourceID; holdingID = t.destinationID
            quantity = t.tradeQuantity ?? 0
            unitPriceMajor = (t.tradeQuantity ?? 0) == 0 ? 0 : t.amount.amount / (t.tradeQuantity ?? 1)
        case .adjustment:
            break
        }
    }
}
