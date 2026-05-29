import SwiftUI

/// Month header (‹ MM/YYYY ›) + weekday row + day grid; days with activity link to detail.
struct MonthGrid: View {
    let store: CalendarStore
    @Binding var pickingMonth: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Button("Previous month", systemImage: "chevron.left") { store.step(-1) }
                    .labelStyle(.iconOnly)
                Spacer()
                Button {
                    pickingMonth = true
                } label: {
                    Text(String(format: "%02d/%d", store.month, store.year)).bold()
                }
                Spacer()
                Button("Next month", systemImage: "chevron.right") { store.step(1) }
                    .labelStyle(.iconOnly)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index]).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(0..<(store.firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: 46)
                }
                ForEach(1...store.daysInMonth, id: \.self) { day in
                    let net = store.dailyNet[day]
                    if net != nil {
                        NavigationLink(value: DayRef(year: store.year, month: store.month, day: day)) {
                            DayCell(day: day, net: net)
                        }
                        .buttonStyle(.plain)
                    } else {
                        DayCell(day: day, net: nil)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            Spacer()
        }
    }
}
