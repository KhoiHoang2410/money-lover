import SwiftUI

/// One envelope: icon, name (+ Reserve badge), spent-of-allocation, remaining, a progress bar, and —
/// when caps are set — this week's / this month's spend against the cap (red + warning glyph if over).
struct EnvelopeRow: View {
    let envelope: Envelope
    let spent: Money
    let remaining: Money
    var weekSpent: Money = .zero(.vnd)
    var monthSpent: Money = .zero(.vnd)

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: envelope.iconName)
                    .foregroundStyle(Theme.Palette.pinkDeep)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(envelope.name).bold()
                        if envelope.isReserve {
                            Text("Reserve")
                                .font(.caption2).bold()
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.Palette.yellowSoft, in: .capsule)
                                .foregroundStyle(Theme.Palette.yellowDeep)
                        }
                    }
                    Text("\(spent.formatted) of \(envelope.allocation.formatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(remaining.amount, format: .currency(code: remaining.currency.rawValue))
                    .bold()
                    .foregroundStyle(remaining.isNegative ? Theme.Palette.bad : Theme.Palette.ink)
                    .accessibilityIdentifier(A11y.Envelope.remaining(envelope.name))
            }
            ProgressView(value: progress)
                .tint(remaining.isNegative ? Theme.Palette.bad : Theme.Palette.pink)

            if let weeklyCap = envelope.weeklyCap {
                EnvelopeCapLine(label: "Week", spent: weekSpent, cap: weeklyCap)
            }
            if let monthlyCap = envelope.monthlyCap {
                EnvelopeCapLine(label: "Month", spent: monthSpent, cap: monthlyCap)
            }
        }
        .padding(.vertical, 4)
    }

    private var progress: Double {
        guard envelope.allocation.minorUnits > 0 else { return 0 }
        return min(1, Double(spent.minorUnits) / Double(envelope.allocation.minorUnits))
    }
}
