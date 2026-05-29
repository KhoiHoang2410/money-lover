import SwiftUI

/// One Schedule line: a status dot (Funded/Pending/Missed), the month, and the planned amount.
struct GoalScheduleRow: View {
    let line: ScheduledContribution
    let status: ScheduleStatus

    var body: some View {
        LabeledContent {
            Text(line.amount.amount, format: .currency(code: "VND"))
        } label: {
            Label {
                Text("\(Self.monthName(line.month)) \(String(line.year))")
            } icon: {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                    .foregroundStyle(color)
                    .accessibilityLabel(accessibilityLabel)
            }
        }
    }

    private var color: Color {
        switch status {
        case .funded: Theme.Palette.ok
        case .pending: Theme.Palette.line
        case .missed: Theme.Palette.bad
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .funded: "Funded"
        case .pending: "Pending"
        case .missed: "Missed"
        }
    }

    private static func monthName(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols[max(0, min(symbols.count - 1, month - 1))]
    }
}
