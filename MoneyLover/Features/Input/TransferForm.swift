import SwiftUI

/// Transfer between the owner's own sources: same-currency, cross-currency (with computed fee), or pay card.
struct TransferForm: View {
    let store: InputStore

    @Environment(\.dismiss) private var dismiss
    @State private var mode: TransferMode = .sameCurrency
    @State private var fromID: UUID?
    @State private var toID: UUID?
    @State private var amountOutMajor: Decimal = 0
    @State private var amountInMajor: Decimal = 0
    @State private var rate: Decimal = 0

    var body: some View {
        Form {
            Picker("Type", selection: $mode) {
                ForEach(TransferMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

            Section {
                Picker("From", selection: $fromID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(fromOptions) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("To", selection: $toID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(toOptions) { Text($0.name).tag(Optional($0.id)) }
                }
            }

            Section {
                LabeledContent(mode == .crossCurrency ? "Amount out" : "Amount") {
                    TextField("Amount", value: $amountOutMajor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                if mode == .crossCurrency {
                    LabeledContent("Amount in") {
                        TextField("Amount", value: $amountInMajor, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Rate") {
                        TextField("Rate", value: $rate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    if let fee = computedFee {
                        LabeledContent("Fee") {
                            Text(fee.amount, format: .currency(code: fee.currency.rawValue))
                                .foregroundStyle(Theme.Palette.pinkDeep)
                        }
                    }
                }
            }
        }
        .navigationTitle("Transfer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!canSave)
            }
        }
    }

    private var fromOptions: [Source] {
        mode == .payCard ? store.sources.filter { $0.kind == .account } : store.sources
    }

    private var toOptions: [Source] {
        switch mode {
        case .payCard: store.sources.filter { $0.kind == .creditCard }
        default: store.sources.filter { $0.id != fromID }
        }
    }

    private var fromSource: Source? { store.sources.first { $0.id == fromID } }
    private var toSource: Source? { store.sources.first { $0.id == toID } }

    private var computedFee: Money? {
        guard mode == .crossCurrency, let from = fromSource, let to = toSource, rate > 0 else { return nil }
        return TransferEngine.fee(
            amountOut: Money(major: amountOutMajor, currency: from.currency),
            amountIn: Money(major: amountInMajor, currency: to.currency),
            rate: rate
        )
    }

    private var canSave: Bool {
        guard let from = fromSource, let to = toSource, from.id != to.id, amountOutMajor > 0 else { return false }
        return mode != .crossCurrency || (amountInMajor > 0 && rate > 0)
    }

    private func save() {
        guard let from = fromSource, let to = toSource else { return }
        let out = Money(major: amountOutMajor, currency: from.currency)
        if mode == .crossCurrency {
            let received = Money(major: amountInMajor, currency: to.currency)
            let transaction = Transaction(
                kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                destinationAmount: received,
                fee: TransferEngine.fee(amountOut: out, amountIn: received, rate: rate),
                note: "Transfer"
            )
            store.add(transaction)
        } else {
            let transaction = Transaction(
                kind: .transfer, amount: out, sourceID: from.id, destinationID: to.id,
                note: mode == .payCard ? "Card payment" : "Transfer"
            )
            store.add(transaction)
        }
        dismiss()
    }
}
