import SwiftUI

/// Scrollable Overview body: net-worth hero + holdings / accounts / credit-card sections.
struct OverviewContent: View {
    let store: OverviewStore
    let censored: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
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
                goalsSection
                section("Credit cards", store.cards)
            }
            .padding(.bottom, Theme.Layout.bottomInset)
        }
        .background(Theme.Palette.background)
    }

    /// A titled group of rows on one flat card, hairline-divided (ADR-0010 calm-neobank).
    @ViewBuilder
    private func section(_ title: String, _ sources: [Source]) -> some View {
        if !sources.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                sectionHeader(title)
                card {
                    ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                        if index > 0 { rowDivider }
                        // `.contentShape` makes the whole row hit-testable (BUG-001).
                        NavigationLink(value: OverviewRoute.account(source.id)) {
                            SourceRow(source: source, balance: store.displayValue(for: source), censored: censored)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(A11y.Overview.sourceRow(source.name))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var goalsSection: some View {
        if !store.fundedGoals.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                sectionHeader("Goals")
                card {
                    ForEach(Array(store.fundedGoals.enumerated()), id: \.element.id) { index, goal in
                        if index > 0 { rowDivider }
                        NavigationLink(value: OverviewRoute.goal(goal.id)) {
                            GoalAssetRow(goal: goal, balance: store.balance(for: goal), censored: censored)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(A11y.Overview.goalRow(goal.name))
                    }
                }
            }
        }
    }

    /// Wraps rows in a flat surface card inset from the screen edges.
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.vertical, Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: Theme.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Theme.Palette.stroke, lineWidth: 1)
            )
            .padding(.horizontal, Theme.Spacing.lg)
    }

    private var rowDivider: some View {
        Divider().overlay(Theme.Palette.stroke)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.Palette.inkSoft)
            .textCase(.uppercase)
            .padding(.horizontal, Theme.Spacing.xl)
    }
}
