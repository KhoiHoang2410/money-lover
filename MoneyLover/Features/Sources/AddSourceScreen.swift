import SwiftUI

/// Form to add a new Source (Account / Credit card / Holding) with an opening balance.
struct AddSourceScreen: View {
    let onSave: (Source) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind: SourceKind = .account
    @State private var currency: Currency = .vnd
    @State private var openingMajor: Decimal = 0
    @State private var iconName = "banknote.fill"
    @State private var logo = Self.noLogo
    @State private var quantity: Decimal = 0
    @State private var unit: HoldingUnit = .chi
    @State private var ticker = ""

    private static let noLogo = "none"
    private let bankLogos = ["mbbank", "vpbank", "vib", "wise"]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(SourceKind.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Currency", selection: $currency) {
                        ForEach(Currency.allCases) { Text($0.rawValue).tag($0) }
                    }
                    LabeledContent("Opening balance") {
                        TextField("Amount", value: $openingMajor, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                if kind == .holding {
                    Section("Holding") {
                        LabeledContent("Quantity") {
                            TextField("Qty", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                        Picker("Unit", selection: $unit) {
                            ForEach(HoldingUnit.allCases) { Text($0.label).tag($0) }
                        }
                        TextField("Ticker (optional)", text: $ticker)
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

    private func save() {
        let minor = NSDecimalNumber(decimal: openingMajor * Decimal(currency.minorUnitScale)).intValue
        let holding: HoldingInfo? = kind == .holding
            ? HoldingInfo(quantity: quantity, unit: unit, ticker: ticker.isEmpty ? nil : ticker)
            : nil
        let source = Source(
            name: name,
            kind: kind,
            currency: currency,
            openingBalance: Money(minorUnits: minor, currency: currency),
            iconName: iconName,
            logoAsset: logo == Self.noLogo ? nil : logo,
            holding: holding
        )
        onSave(source)
        dismiss()
    }
}

#Preview {
    AddSourceScreen(onSave: { _ in })
}
