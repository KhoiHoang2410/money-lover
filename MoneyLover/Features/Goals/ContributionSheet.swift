import SwiftUI

/// Sheet to record a contribution toward a goal.
struct ContributionSheet: View {
    let onSave: (Money) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountMajor: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent("Amount (₫)") {
                    TextField("Amount", value: $amountMajor, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .navigationTitle("Add contribution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(Money(major: amountMajor, currency: .vnd))
                        dismiss()
                    }
                    .disabled(amountMajor <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
