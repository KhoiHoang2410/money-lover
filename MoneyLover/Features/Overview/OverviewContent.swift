import SwiftUI

/// Scrollable Overview body: net-worth hero + holdings / accounts / credit-card sections.
struct OverviewContent: View {
    let store: OverviewStore
    let censored: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                NetWorthHeader(netWorth: store.netWorth, censored: censored)

                if store.sources.isEmpty {
                    ContentUnavailableView(
                        "No sources yet",
                        systemImage: "creditcard",
                        description: Text("Add accounts, cards, or holdings in Config → Sources.")
                    )
                    .padding(.top, Theme.Spacing.xl)
                }

                section("Holdings", store.holdings)
                section("Accounts", store.accounts)
                section("Credit cards", store.cards)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ sources: [Source]) -> some View {
        if !sources.isEmpty {
            Text(title)
                .font(.footnote).bold()
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
            ForEach(sources) { source in
                SourceRow(source: source, balance: store.balance(for: source), censored: censored)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }
}
