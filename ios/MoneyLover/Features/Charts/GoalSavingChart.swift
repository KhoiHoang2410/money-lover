import SwiftUI
import Charts

/// Cumulative saving per Goal over the last six months, one line per goal.
struct GoalSavingChart: View {
    let store: ChartsStore

    var body: some View {
        Chart {
            ForEach(store.goals) { goal in
                ForEach(store.savingPoints(for: goal)) { point in
                    LineMark(
                        x: .value("Month", point.date, unit: .month),
                        y: .value("Saved", point.value.minorUnits)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(by: .value("Goal", goal.name))
                }
            }
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
        .frame(height: 180)
    }
}
