import SwiftUI

/// The stacked chart cards. Extracted so `ImageRenderer` can snapshot exactly what's on screen.
struct ChartsContent: View {
    @Bindable var store: ChartsStore

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ChartCard(title: "Total balance over time", subtitle: "net worth · VND") {
                BalanceTrendChart(points: store.balancePoints)
            }
            ChartCard(title: "Spending over time", subtitle: "total spent / month") {
                SpendingTrendChart(points: store.spendingPoints)
            }
            ChartCard(title: "Spending per bucket over time") {
                BucketSpendingChart(store: store)
            }
            ChartCard(title: "Saving per goal over time", subtitle: "cumulative · VND") {
                GoalSavingChart(store: store)
            }
        }
    }
}
