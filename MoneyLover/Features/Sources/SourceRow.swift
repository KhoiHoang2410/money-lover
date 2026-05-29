import SwiftUI

/// A single source row: icon, name, kind/holding subtitle, and opening balance.
struct SourceRow: View {
    let source: Source
    let balance: Money
    var censored: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            SourceIcon(source: source)
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name).bold()
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(money: balance, censored: censored)
                .bold()
                .foregroundStyle(source.kind.isLiability ? Theme.Palette.bad : Theme.Palette.ink)
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if let holding = source.holding {
            let qty = holding.quantity.formatted(.number)
            return "\(source.kind.title) · \(qty) \(holding.unit.label)"
        }
        return "\(source.kind.title) · \(source.currency.rawValue)"
    }
}
