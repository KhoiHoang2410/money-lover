import SwiftUI

/// One Schedule line: a status dot (Funded/Due/Pending/Missed), the month, the planned amount, the
/// shortfall on a due/missed line, and that month's actual Contributions (date + trimmed note).
struct GoalScheduleRow: View {
    let line: ScheduledContribution
    let status: ScheduleStatus
    var shortfall: Money?
    var contributions: [Contribution] = []

    /// Contribution notes are trimmed to this many characters in this compact list.
    private static let descLimit = 32

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
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

            if let shortfall, shortfall.minorUnits > 0, status == .due || status == .missed {
                Text("Missing \(shortfall.amount.formatted(.currency(code: "VND")))")
                    .font(.caption)
                    .foregroundStyle(color)
            }

            ForEach(contributions) { contribution in
                HStack(spacing: Theme.Spacing.sm) {
                    Text(contribution.date, format: .dateTime.day().month())
                        .foregroundStyle(.secondary)
                    Text(Self.trimmed(contribution.note))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.sm)
                    Text(contribution.amount.amount, format: .currency(code: "VND"))
                        .foregroundStyle(Theme.Palette.ok)
                }
                .font(.caption)
            }
        }
    }

    private var color: Color {
        switch status {
        case .funded: Theme.Palette.ok
        case .due: Theme.Palette.warn
        case .pending: Theme.Palette.line
        case .missed: Theme.Palette.bad
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .funded: "Funded"
        case .due: "Due"
        case .pending: "Pending"
        case .missed: "Missed"
        }
    }

    private static func trimmed(_ note: String) -> String {
        note.count > descLimit ? note.prefix(descLimit) + "…" : note
    }

    private static func monthName(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols[max(0, min(symbols.count - 1, month - 1))]
    }
}
