import SwiftUI
import Charts

/// Total spending per month for the last six months.
struct SpendingTrendChart: View {
    let points: [MonthPoint]

    var body: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Month", point.date, unit: .month),
                y: .value("Spent", point.value.minorUnits)
            )
            .cornerRadius(Theme.Spacing.xs)
            .foregroundStyle(Theme.Palette.pink)
        }
        .chartXAxis { AxisMarks(values: .stride(by: .month)) { _ in AxisValueLabel(format: .dateTime.month(.abbreviated)) } }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let raw = value.as(Int.self) { Text(ChartFormat.compact(Money(minorUnits: raw, currency: .vnd))) }
                }
            }
        }
        .frame(height: 160)
    }
}
