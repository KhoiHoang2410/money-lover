import SwiftUI
import Charts

/// Per-Envelope spending with a 7d / 30d / 6m range switch. Bars are scaled to average-per-day
/// for the 30d and 6m ranges; refuses with an explicit message when history is too short.
struct BucketSpendingChart: View {
    @Bindable var store: ChartsStore

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Picker("Range", selection: $store.range) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            switch store.bucketSpending() {
            case let .series(series):
                seriesChart(series)
                Text(unitCaption).font(.caption).foregroundStyle(.secondary)
            case let .insufficientHistory(have, need):
                refusal(have: have, need: need)
            }
        }
    }

    private var unitCaption: String {
        store.range.usesAveragePerDay
            ? "₫ spent · each bar = average per day (comparable across ranges)"
            : "₫ spent · daily"
    }

    @ViewBuilder
    private func seriesChart(_ series: [EnvelopeSpendSeries]) -> some View {
        Chart {
            ForEach(series) { envelope in
                ForEach(envelope.bars) { bar in
                    BarMark(
                        x: .value("Period", bar.label),
                        y: .value("₫/day", bar.averagePerDay.minorUnits)
                    )
                    .cornerRadius(Theme.Spacing.xs)
                    .foregroundStyle(by: .value("Envelope", envelope.name))
                    .position(by: .value("Envelope", envelope.name))
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let raw = value.as(Int.self) { Text(ChartFormat.compact(Money(minorUnits: raw, currency: .vnd))) }
                }
            }
        }
        .frame(height: 200)
    }

    @ViewBuilder
    private func refusal(have: Int, need: Int) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("Not enough data for \(store.range.title.lowercased())")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.Palette.bad)
            Text("need ≥ \(need) days of history · you have \(have)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.pinkSoft, in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
    }
}
