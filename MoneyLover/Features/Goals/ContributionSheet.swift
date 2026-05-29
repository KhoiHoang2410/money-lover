import SwiftUI

/// Sheet to fund a goal: an amount transferred from a chosen VND Account (ADR-0007).
struct ContributionSheet: View {
    let accounts: [Source]
    let onSave: (_ amount: Money, _ fromAccountID: UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountMajor: Decimal = 0
    @State private var fromAccountID: UUID?

    private var canSave: Bool { amountMajor > 0 && fromAccountID != nil }

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Amount (₫)") {
                    TextField("Amount", value: $amountMajor, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                Picker("From", selection: $fromAccountID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(accounts) { account in
                        Text(account.name).tag(Optional(account.id))
                    }
                }
                if accounts.isEmpty {
                    Text("Add a VND account first to fund a goal.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add money")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let fromAccountID else { return }
                        onSave(Money(major: amountMajor, currency: .vnd), fromAccountID)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
