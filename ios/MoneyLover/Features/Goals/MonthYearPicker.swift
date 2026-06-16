import SwiftUI

/// A compact month + year selector for a `YearMonth`. Two menu pickers (month name, year) so the
/// owner picks a *month*, never an exact day — contributions to a Goal are monthly.
struct MonthYearPicker: View {
    let title: String
    @Binding var selection: YearMonth
    let years: ClosedRange<Int>

    private static let monthSymbols = Calendar.current.shortMonthSymbols

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Picker("Month", selection: monthBinding) {
                    ForEach(1...12, id: \.self) { m in
                        Text(Self.monthSymbols[m - 1]).tag(m)
                    }
                }
                Picker("Year", selection: yearBinding) {
                    ForEach(Array(years), id: \.self) { y in
                        Text(verbatim: String(y)).tag(y)
                    }
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    private var monthBinding: Binding<Int> {
        Binding(get: { selection.month }, set: { selection = YearMonth(year: selection.year, month: $0) })
    }

    private var yearBinding: Binding<Int> {
        Binding(get: { selection.year }, set: { selection = YearMonth(year: $0, month: selection.month) })
    }
}
