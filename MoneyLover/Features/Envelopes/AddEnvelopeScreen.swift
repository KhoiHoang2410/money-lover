import SwiftUI

/// Form to add a budget envelope with a monthly allocation (VND).
struct AddEnvelopeScreen: View {
    let onSave: (Envelope) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = "fork.knife"
    @State private var allocationMajor: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    LabeledContent("Allocation (₫)") {
                        TextField("Amount", value: $allocationMajor, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Section("Icon") {
                    IconPicker(selection: $iconName)
                }
            }
            .navigationTitle("Add envelope")
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
        let envelope = Envelope(
            name: name,
            iconName: iconName,
            allocation: Money(major: allocationMajor, currency: .vnd)
        )
        onSave(envelope)
        dismiss()
    }
}
