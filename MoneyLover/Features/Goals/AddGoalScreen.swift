import SwiftUI

/// Form to add a goal. A flat monthly plan is generated from now to the target date
/// (the schedule model supports arbitrary per-month amounts; a richer editor can come later).
struct AddGoalScreen: View {
    let onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = "target"
    @State private var targetMajor: Decimal = 0
    @State private var targetDate = Date.now
    @State private var monthlyMajor: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    LabeledContent("Target (₫)") {
                        TextField("Amount", value: $targetMajor, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                    LabeledContent("Monthly plan (₫)") {
                        TextField("Amount", value: $monthlyMajor, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section("Icon") {
                    IconPicker(selection: $iconName)
                }
            }
            .navigationTitle("Add goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(name.isEmpty || targetMajor <= 0)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }

    private func save() {
        let goal = Goal(
            name: name,
            iconName: iconName,
            target: Money(major: targetMajor, currency: .vnd),
            targetDate: targetDate,
            schedule: makeSchedule()
        )
        onSave(goal)
        dismiss()
    }

    private func makeSchedule() -> [ScheduledContribution] {
        guard monthlyMajor > 0 else { return [] }
        let calendar = Calendar.current
        let amount = Money(major: monthlyMajor, currency: .vnd)
        let start = calendar.dateComponents([.year, .month], from: .now)
        let end = calendar.dateComponents([.year, .month], from: targetDate)
        var year = start.year ?? 0
        var month = start.month ?? 1
        let endIndex = (end.year ?? 0) * 12 + ((end.month ?? 1) - 1)
        var result: [ScheduledContribution] = []
        while year * 12 + (month - 1) <= endIndex && result.count < 600 {
            result.append(ScheduledContribution(year: year, month: month, amount: amount))
            month += 1
            if month > 12 { month = 1; year += 1 }
        }
        return result
    }
}
