import SwiftUI

/// Form to add a new Source (Account / Credit card / Holding) with an opening balance.
struct AddSourceScreen: View {
    let onSave: (Source) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: SourceKind = .account
    @State private var currency: Currency = .vnd
    @State private var openingMajor: Decimal = 0
    @State private var openingText = ""
    @State private var iconName = "banknote.fill"
    @State private var logo = Self.noLogo

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
                        TextField("Amount", text: $openingText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier(A11y.Source.openingBalance)
                            .onChange(of: openingText) { _, newValue in
                                // Re-group in onChange (not the binding setter), else SwiftUI drops the
                                // mid-keystroke reformat. Keyed to the currency's fraction digits.
                                let formatted = openingFormatter.format(newValue)
                                if formatted != newValue { openingText = formatted }
                                openingMajor = openingFormatter.value(formatted)
                            }
                    }
                    .onChange(of: currency) { _, _ in
                        // A new currency changes the allowed fraction digits — re-group the display.
                        openingText = openingFormatter.display(for: openingMajor)
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
            .navigationTitle("Add source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }

    /// Live grouping for the opening balance, keyed to the selected currency's fraction digits
    /// (0 for VND, 2 for USD/SGD). Shows "1.000.000" / "1,000,000" as the user types while keeping
    /// `openingMajor` exact.
    private var openingFormatter: AmountInputFormatter {
        AmountInputFormatter(maximumFractionDigits: currency.fractionDigits)
    }

    private func save() {
        let minor = NSDecimalNumber(decimal: openingMajor * Decimal(currency.minorUnitScale)).intValue
        let source = Source(
            name: name,
            kind: kind,
            currency: currency,
            openingBalance: Money(minorUnits: minor, currency: currency),
            iconName: iconName,
            logoAsset: logo == Self.noLogo ? nil : logo
        )
        onSave(source)
        dismiss()
    }
}

#Preview {
    AddSourceScreen(onSave: { _ in })
}
