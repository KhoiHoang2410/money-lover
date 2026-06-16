import SwiftUI

/// Sheet to manually override a single rate's value.
struct RateOverrideSheet: View {
    let key: String
    let current: Decimal
    let onSave: (Decimal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                LabeledContent(RateRow.title(for: key)) {
                    AmountField("Value", value: $value, fractionDigits: 6)
                }
            }
            .navigationTitle("Override rate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(value); dismiss() }.disabled(value <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
            .onAppear { value = current }
        }
    }
}
