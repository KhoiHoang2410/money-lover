import SwiftUI

/// Month header (‹ MM/YYYY ›) + weekday row + day grid; days with activity link to detail.
struct MonthGrid: View {
    let store: CalendarStore
    @Binding var pickingMonth: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.md) {
                Button("Previous month", systemImage: "chevron.left") { store.step(-1) }
                    .labelStyle(.iconOnly)
                Button {
                    pickingMonth = true
                } label: {
                    Text(String(format: "%02d/%d", store.month, store.year)).bold()
                }
                Button("Next month", systemImage: "chevron.right") { store.step(1) }
                    .labelStyle(.iconOnly)
                Spacer()
                Button("Today") { store.jumpToToday() }
                    .buttonStyle(.bordered)
                    .tint(Theme.Palette.pink)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(weekdays[index]).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(0..<(store.firstWeekday - 1), id: \.self) { _ in
                    Color.clear.frame(height: 52)
                }
                ForEach(1...store.daysInMonth, id: \.self) { day in
                    let net = store.dailyNet[day]
                    if net != nil {
                        Button {
                            store.selectedDay = (store.selectedDay == day) ? nil : day
                        } label: {
                            DayCell(day: day, net: net, isSelected: store.selectedDay == day, isToday: store.isToday(day))
                        }
                        .buttonStyle(.plain)
                        // Only days with activity are buttons; the id lets a test assert a write
                        // surfaced on the right day (a day with no net carries no id).
                        .accessibilityIdentifier(A11y.Calendar.day(day))
                    } else {
                        DayCell(day: day, net: nil, isSelected: store.selectedDay == day, isToday: store.isToday(day))
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }
}
