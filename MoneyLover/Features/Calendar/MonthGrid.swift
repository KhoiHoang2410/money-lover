import SwiftUI

/// Month header (‹ MM/YYYY ›) + weekday row + day grid; every day is tappable to open its detail.
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
                    .accessibilityIdentifier(A11y.Calendar.prevMonth)
                Button {
                    pickingMonth = true
                } label: {
                    Text(String(format: "%02d/%d", store.month, store.year)).bold()
                }
                .accessibilityIdentifier(A11y.Calendar.monthLabel)
                Button("Next month", systemImage: "chevron.right") { store.step(1) }
                    .labelStyle(.iconOnly)
                    .accessibilityIdentifier(A11y.Calendar.nextMonth)
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
                    // Every day is selectable — even a blank one — so the floating + can prefill it.
                    // Keep the net split as an explicit if/else: collapsing every cell into one bare
                    // Button shrinks the grid's view tree enough that XCUITest's accessibility
                    // snapshot drops the first row (where "today" sits), so both branches stay Buttons.
                    if net != nil {
                        dayButton(day, net: net)
                    } else {
                        dayButton(day, net: nil)
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
    }

    /// A tappable day: toggles the inline detail and prefills the floating + with this date.
    private func dayButton(_ day: Int, net: Money?) -> some View {
        Button {
            store.selectedDay = (store.selectedDay == day) ? nil : day
        } label: {
            DayCell(day: day, net: net, isSelected: store.selectedDay == day, isToday: store.isToday(day))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11y.Calendar.day(day))
    }
}
