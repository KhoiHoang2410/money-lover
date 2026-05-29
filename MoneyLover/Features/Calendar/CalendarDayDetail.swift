import SwiftUI

/// The transactions for the calendar's selected day, shown inline below the grid in the space
/// the month leaves. Prompts to pick a day when nothing is selected.
struct CalendarDayDetail: View {
    let store: CalendarStore

    var body: some View {
        Group {
            if let day = store.selectedDay {
                let transactions = store.transactions(onDay: day)
                if transactions.isEmpty {
                    ContentUnavailableView("No transactions", systemImage: "calendar")
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal, Theme.Spacing.xl)
                                Divider()
                            }
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Pick a day",
                    systemImage: "hand.tap",
                    description: Text("Tap a highlighted day to see its transactions.")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
