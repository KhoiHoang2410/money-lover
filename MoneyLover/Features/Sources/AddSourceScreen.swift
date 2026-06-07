import SwiftUI

/// Form to add a new Source (Account / Credit card) or edit an existing one — including updating its
/// opening balance (feat). Holdings (gold/stock) are managed on the dedicated Holdings screen.
struct AddSourceScreen: View {
    /// When set, the form edits this source in place (Save keeps its id). Nil = add a new one.
    var editing: Source?
    let onSave: (Source) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: SourceKind = .account
    @State private var currency: Currency = .vnd
    @State private var openingMajor: Decimal = 0
    @State private var iconName = "banknote.fill"
    @State private var logo = Self.noLogo
    @State private var loaded = false

    private static let noLogo = "none"
    private let bankLogos = ["mbbank", "vpbank", "vib", "wise"]
    /// Holdings (gold/stock) are added on the dedicated Holdings screen (ADR-0010), not here.
    private let sourceKinds: [SourceKind] = [.account, .creditCard]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(sourceKinds) { Text($0.title).tag($0) }
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases) { Text($0.rawValue).tag($0) }
                    }
                    LabeledContent("Opening balance") {
                        // Live grouping keyed to the selected currency's fraction digits (0 VND / 2 USD,SGD);
                        // a currency switch re-renders the display, keeping `openingMajor` exact.
                        AmountField("Amount", value: $openingMajor, fractionDigits: currency.fractionDigits, accessibilityID: A11y.Source.openingBalance)
                    }
                }
                if kind == .account {
                    Section("Bank logo") {
                        Picker("Logo", selection: $logo) {
                            Text("None").tag(Self.noLogo)
                            ForEach(bankLogos, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("Icon") {
                    IconPicker(selection: $iconName)
                }
            }
            .navigationTitle(editing == nil ? "Add source" : "Edit source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    /// Populate the form once from the edited source (no-op when adding).
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let source = editing else { return }
        name = source.name
        kind = source.kind == .holding ? .account : source.kind
        currency = source.currency
        openingMajor = source.openingBalance.amount
        iconName = source.iconName
        logo = source.logoAsset ?? Self.noLogo
    }

    private func save() {
        let minor = NSDecimalNumber(decimal: openingMajor * Decimal(currency.minorUnitScale)).intValue
        let source = Source(
            id: editing?.id ?? UUID(),
            name: name,
            kind: kind,
            currency: currency,
            openingBalance: Money(minorUnits: minor, currency: currency),
            iconName: iconName,
            logoAsset: logo == Self.noLogo ? nil : logo,
            holding: editing?.holding
        )
        onSave(source)
        dismiss()
    }
}

#Preview {
    AddSourceScreen(onSave: { _ in })
}
