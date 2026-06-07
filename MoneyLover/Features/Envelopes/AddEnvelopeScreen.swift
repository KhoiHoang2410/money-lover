import SwiftUI

/// Form to add a budget envelope, or edit one in place: its monthly allocation plus optional
/// weekly and monthly spending caps (feat: tap an envelope to adjust its caps). Amounts are VND.
struct AddEnvelopeScreen: View {
    /// When set, the form edits this envelope in place (Save keeps its id, carried, and Reserve flag).
    var editing: Envelope?
    let onSave: (Envelope) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = "fork.knife"
    @State private var allocationMajor: Decimal = 0
    /// 0 means "no cap" (stored as nil).
    @State private var weeklyCapMajor: Decimal = 0
    @State private var monthlyCapMajor: Decimal = 0
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    amountRow("Allocation (₫)", value: $allocationMajor)
                }
                Section {
                    amountRow("Cap per week (₫)", value: $weeklyCapMajor)
                    amountRow("Cap per month (₫)", value: $monthlyCapMajor)
                } header: {
                    Text("Spending caps")
                } footer: {
                    Text("Optional. Leave at 0 for no cap. Money Lover warns you when this week's or this month's spending reaches the cap.")
                }
                Section("Icon") {
                    IconPicker(selection: $iconName)
                }
            }
            .navigationTitle(editing == nil ? "Add envelope" : "Edit envelope")
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

    private func amountRow(_ title: String, value: Binding<Decimal>) -> some View {
        LabeledContent(title) {
            TextField("Amount", value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let envelope = editing else { return }
        name = envelope.name
        iconName = envelope.iconName
        allocationMajor = envelope.allocation.amount
        weeklyCapMajor = envelope.weeklyCap?.amount ?? 0
        monthlyCapMajor = envelope.monthlyCap?.amount ?? 0
    }

    private func save() {
        let envelope = Envelope(
            id: editing?.id ?? UUID(),
            name: name,
            iconName: iconName,
            allocation: Money(major: allocationMajor, currency: .vnd),
            carried: editing?.carried ?? .zero(.vnd),
            isReserve: editing?.isReserve ?? false,
            weeklyCap: cap(weeklyCapMajor),
            monthlyCap: cap(monthlyCapMajor)
        )
        onSave(envelope)
        dismiss()
    }

    /// A positive major amount becomes a VND cap; 0 or less means no cap.
    private func cap(_ major: Decimal) -> Money? {
        major > 0 ? Money(major: major, currency: .vnd) : nil
    }
}

#Preview {
    AddEnvelopeScreen(onSave: { _ in })
}
