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

                section("Holdings", store.holdings, tappable: true)
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
                // `.contentShape` makes the whole row (including the Spacer gap) hit-testable; with
                // `.buttonStyle(.plain)` only the drawn content is tappable, so taps landing on the
                // empty middle of a row would otherwise do nothing (BUG-001).
                let row = SourceRow(source: source, balance: store.displayValue(for: source), censored: censored)
                    .contentShape(.rect)
                if tappable {
                    NavigationLink(value: OverviewRoute.account(source.id)) { row }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .accessibilityIdentifier(A11y.Overview.sourceRow(source.name))
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
                NavigationLink(value: OverviewRoute.goal(goal.id)) {
                    GoalAssetRow(goal: goal, balance: store.balance(for: goal), censored: censored)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Theme.Spacing.xl)
                .accessibilityIdentifier(A11y.Overview.goalRow(goal.name))
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
