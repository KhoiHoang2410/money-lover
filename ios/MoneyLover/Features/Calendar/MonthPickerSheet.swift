import SwiftUI

/// Pick a month within a year (year nav + 12-month grid).
struct MonthPickerSheet: View {
    let initialYear: Int
    let onPick: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var year = 0

    private let columns = Array(repeating: GridItem(.flexible()), count: 3)

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                HStack {
                    Button("Previous year", systemImage: "chevron.left") { year -= 1 }
                        .labelStyle(.iconOnly)
                    Spacer()
                    Text(String(year)).font(.title2).bold()
                    Spacer()
                    Button("Next year", systemImage: "chevron.right") { year += 1 }
                        .labelStyle(.iconOnly)
                }
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(1...12, id: \.self) { month in
                        Button(monthName(month)) {
                            onPick(year, month)
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(Theme.Spacing.xl)
            .navigationTitle("Pick month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
            .onAppear { year = initialYear }
        }
    }

    private func monthName(_ month: Int) -> String {
        let symbols = Calendar.current.shortMonthSymbols
        return symbols[max(0, min(symbols.count - 1, month - 1))]
    }
}
