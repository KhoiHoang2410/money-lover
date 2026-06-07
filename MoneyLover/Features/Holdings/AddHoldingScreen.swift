import SwiftUI

/// Form to add a Holding (gold or stock) by **quantity only** — never a money amount (ADR-0010) —
/// or edit an existing one, including updating its opening quantity (feat). Gold takes a quantity +
/// unit (chỉ/lượng); Stock takes a share count + a bundled HOSE/HNX symbol.
struct AddHoldingScreen: View {
    /// When set, the form edits this holding in place (Save keeps its id). Nil = add a new one.
    var editing: Source?
    let onSave: (Source) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var assetType: HoldingAssetType = .gold
    @State private var name = "Gold"
    @State private var quantity: Decimal = 0
    @State private var goldUnit: HoldingUnit = .chi
    @State private var ticker: VNTicker?
    /// The stock symbol when editing — kept so an unchanged ticker survives without re-picking it.
    @State private var editedTickerSymbol: String?
    @State private var pickingStock = false
    /// True once the user has edited the name, so auto-fill stops overwriting their choice.
    @State private var nameEdited = false
    @State private var loaded = false

    private let goldUnits: [HoldingUnit] = [.chi, .luong]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Asset", selection: $assetType) {
                        ForEach(HoldingAssetType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier(A11y.Holding.assetType)
                }

                Section {
                    TextField("Name", text: $name)
                        .onChange(of: name) { _, _ in nameEdited = true }
                    LabeledContent(assetType == .gold ? "Quantity" : "Shares") {
                        // Up to 4 fraction digits for fractional gold weights (chỉ/lượng); shares are whole.
                        AmountField("Qty", value: $quantity, fractionDigits: 4, accessibilityID: A11y.Holding.quantity)
                    }
                    if assetType == .gold {
                        Picker("Unit", selection: $goldUnit) {
                            ForEach(goldUnits) { Text($0.label).tag($0) }
                        }
                        .accessibilityIdentifier(A11y.Holding.unit)
                    } else {
                        Button {
                            pickingStock = true
                        } label: {
                            LabeledContent("Stock") {
                                Text(selectedSymbol ?? "Select…")
                                    .foregroundStyle(selectedSymbol == nil ? .secondary : .primary)
                            }
                        }
                        .accessibilityIdentifier(A11y.Holding.stockPicker)
                    }
                }
            }
            .navigationTitle(editing == nil ? "Add holding" : "Edit holding")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                        .accessibilityIdentifier(A11y.Holding.save)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
            .sheet(isPresented: $pickingStock) {
                StockPickerSheet { picked in
                    ticker = picked
                    editedTickerSymbol = picked.symbol
                    if !nameEdited { name = picked.name }
                }
            }
            .onChange(of: assetType) { _, newValue in
                // Reset the unit and a stale auto-name when flipping asset type.
                if newValue == .gold {
                    goldUnit = .chi
                    if !nameEdited { name = "Gold" }
                } else if !nameEdited {
                    name = ticker?.name ?? ""
                }
            }
            .onAppear(perform: loadIfNeeded)
        }
    }

    /// The stock symbol to show: a freshly-picked ticker, else the one we're editing.
    private var selectedSymbol: String? { ticker?.symbol ?? editedTickerSymbol }

    private var canSave: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty, quantity > 0 else { return false }
        return assetType == .gold || selectedSymbol != nil
    }

    /// Populate the form once from the edited holding (no-op when adding).
    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let source = editing, let holding = source.holding else { return }
        // Editing means the name is the owner's choice — stop the auto-fill from clobbering it.
        nameEdited = true
        name = source.name
        quantity = holding.quantity
        if let symbol = holding.ticker, !symbol.isEmpty {
            assetType = .stock
            editedTickerSymbol = symbol
        } else {
            assetType = .gold
            goldUnit = holding.unit
        }
    }

    private func save() {
        let holding: HoldingInfo
        let icon: String
        switch assetType {
        case .gold:
            holding = HoldingInfo(quantity: quantity, unit: goldUnit, ticker: nil)
            icon = assetType.iconName
        case .stock:
            holding = HoldingInfo(quantity: quantity, unit: .shares, ticker: selectedSymbol)
            icon = assetType.iconName
        }
        let source = Source(
            id: editing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            kind: .holding,
            currency: .vnd,
            openingBalance: .zero(.vnd),
            iconName: icon,
            holding: holding
        )
        onSave(source)
        dismiss()
    }
}

#Preview {
    AddHoldingScreen(onSave: { _ in })
}
