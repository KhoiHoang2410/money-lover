import SwiftUI

/// A single source row: icon, name, kind/holding subtitle, and opening balance.
struct SourceRow: View {
    let source: Source
    let balance: Money
    /// VND value of a foreign-currency balance, shown beneath the native amount. `nil` hides it.
    var vndEquivalent: Money? = nil
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
            VStack(alignment: .trailing, spacing: 2) {
                AmountText(money: balance, censored: censored)
                    .bold()
                    .foregroundStyle(source.kind.isLiability ? Theme.Palette.bad : Theme.Palette.ink)
                if let vndEquivalent, !censored {
                    Text(verbatim: "≈ \(vndEquivalent.formatted)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
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
