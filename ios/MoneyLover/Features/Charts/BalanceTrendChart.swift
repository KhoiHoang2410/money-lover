import SwiftUI
import Charts

/// Net-worth-over-time line for the last six months (valued at current rates).
struct BalanceTrendChart: View {
    let points: [MonthPoint]

    var body: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Month", point.date, unit: .month),
                y: .value("Net worth", point.value.minorUnits)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Theme.heroGradient)
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
