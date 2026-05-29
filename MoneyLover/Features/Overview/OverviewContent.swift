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

                section("Holdings", store.holdings, tappable: false)
                section("Accounts", store.accounts, tappable: true)
                goalsSection
                section("Credit cards", store.cards, tappable: true)
            }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ sources: [Source], tappable: Bool) -> some View {
        if !sources.isEmpty {
            sectionHeader(title)
            ForEach(sources) { source in
                let row = SourceRow(source: source, balance: store.displayValue(for: source), censored: censored)
                if tappable {
                    NavigationLink(value: source) { row }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.Spacing.xl)
                } else {
                    row.padding(.horizontal, Theme.Spacing.xl)
                }
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        if !store.fundedGoals.isEmpty {
            sectionHeader("Goals")
            ForEach(store.fundedGoals) { goal in
                GoalAssetRow(goal: goal, balance: store.balance(for: goal), censored: censored)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote).bold()
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.top, Theme.Spacing.sm)
    }
}
