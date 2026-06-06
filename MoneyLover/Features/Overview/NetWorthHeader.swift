import SwiftUI

/// The flat deep-green hero showing net worth, total asset, and total debt (all VND).
/// Calm-neobank language (ADR-0010): a solid pine-teal panel, no gradient; asset/debt read as
/// quiet sub-stats split by a hairline rather than competing color blocks.
struct NetWorthHeader: View {
    let netWorth: NetWorth
    let censored: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Net worth")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Theme.Palette.onHero.opacity(0.7))
            AmountText(money: netWorth.net, censored: censored)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Theme.Palette.onHero)
                .accessibilityIdentifier(A11y.Overview.netWorth)

            HStack(spacing: Theme.Spacing.xl) {
                stat("Asset", netWorth.asset)
                    .accessibilityIdentifier(A11y.Overview.asset)
                Divider()
                    .frame(height: 28)
                    .overlay(Theme.Palette.onHero.opacity(0.2))
                stat("Debt", netWorth.debt)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background(Theme.heroFill, in: .rect(cornerRadius: Theme.Radius.hero))
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
    }

    private func stat(_ label: String, _ money: Money) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.Palette.onHero.opacity(0.7))
            AmountText(money: money, censored: censored)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Palette.onHero)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
