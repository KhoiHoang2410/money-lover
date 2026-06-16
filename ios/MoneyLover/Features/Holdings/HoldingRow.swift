import SwiftUI

/// A single Holding row: icon, name, live quantity + unit, and current VND value.
struct HoldingRow: View {
    let holding: Source
    let quantity: Decimal
    let value: Money

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            SourceIcon(source: holding)
            VStack(alignment: .leading, spacing: 2) {
                Text(holding.name).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(money: value)
                .bold()
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityIdentifier(A11y.Holding.value(holding.name))
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        let qty = quantity.formatted(.number)
        if let ticker = holding.holding?.ticker, !ticker.isEmpty {
            return "\(ticker) · \(qty) \(holding.holding?.unit.label ?? "")"
        }
        return "Gold · \(qty) \(holding.holding?.unit.label ?? "")"
    }
}
