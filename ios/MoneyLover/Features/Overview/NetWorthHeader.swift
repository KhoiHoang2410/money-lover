import SwiftUI

/// The gradient hero showing net worth, total asset, and total debt (all VND).
struct NetWorthHeader: View {
    let netWorth: NetWorth
    let censored: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label("Net worth", systemImage: "rectangle.stack.fill")
                .font(.subheadline)
                .opacity(0.95)
            AmountText(money: netWorth.net, censored: censored)
                .font(.largeTitle).bold()
                .accessibilityIdentifier(A11y.Overview.netWorth)

            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Asset").font(.caption).opacity(0.9)
                    AmountText(money: netWorth.asset, censored: censored).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
                .background(.white.opacity(0.2), in: .rect(cornerRadius: 14))
                .accessibilityIdentifier(A11y.Overview.asset)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Debt").font(.caption).opacity(0.9)
                    AmountText(money: netWorth.debt, censored: censored).bold()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.sm)
                .background(.black.opacity(0.18), in: .rect(cornerRadius: 14))
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.xl)
        .background(Theme.heroGradient)
        .clipShape(.rect(cornerRadius: Theme.Radius.hero))
        .padding(Theme.Spacing.lg)
    }
}
