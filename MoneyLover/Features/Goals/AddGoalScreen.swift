import SwiftUI

/// Form to add a goal. The owner picks a **target amount** and a **start/end month**; a flat
/// monthly plan that sums exactly to the target is generated across that window
/// (the schedule model supports arbitrary per-month amounts; a richer editor can come later).
struct AddGoalScreen: View {
    let onSave: (Goal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var iconName = "target"
    @State private var targetMajor: Decimal = 0
    @State private var startMonth = YearMonth.containing(.now)
    @State private var endMonth = YearMonth.containing(.now).adding(11)

    /// Year span offered in the pickers: this year through ten years out.
    private var years: ClosedRange<Int> {
        let thisYear = YearMonth.containing(.now).year
        return thisYear...(thisYear + 10)
    }

    private var target: Money { Money(major: targetMajor, currency: .vnd) }
    private var monthCount: Int { startMonth.monthsThrough(endMonth) }
    private var windowIsValid: Bool { endMonth >= startMonth }
    private var monthlyAmount: Money {
        guard monthCount > 0 else { return .zero(.vnd) }
        return Money(minorUnits: target.minorUnits / monthCount, currency: .vnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    LabeledContent("Target (₫)") {
                        TextField("Amount", value: $targetMajor, format: .number)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                    MonthYearPicker(title: "Start month", selection: $startMonth, years: years)
                    MonthYearPicker(title: "End month", selection: $endMonth, years: years)
                } footer: {
                    planFooter
                }
                Section("Icon") {
                    IconPicker(selection: $iconName)
                }
            }
            .navigationTitle("Add goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.isEmpty || targetMajor <= 0 || !windowIsValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }

    @ViewBuilder private var planFooter: some View {
        if !windowIsValid {
            Text("End month must be on or after the start month.")
                .foregroundStyle(Theme.Palette.bad)
        } else if targetMajor > 0 {
            Text("≈ \(monthlyAmount.formatted) / month over \(monthCount) month\(monthCount == 1 ? "" : "s").")
        }
    }

    private func save() {
        let goal = Goal(
            name: name,
            iconName: iconName,
            target: target,
            startMonth: startMonth,
            endMonth: endMonth,
            schedule: GoalScheduleBuilder.flatSchedule(target: target, start: startMonth, end: endMonth)
        )
        onSave(goal)
        dismiss()
    }
}
