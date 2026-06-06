import SwiftUI

/// The transactions for the calendar's selected day, shown inline below the grid in the space
/// the month leaves. Tapping a row opens it: everyday kinds into the edit form, an Adjustment into a
/// read-only view that still offers Delete (feat). Prompts to pick a day when nothing is selected.
struct CalendarDayDetail: View {
    let store: CalendarStore
    let onEdit: (Transaction) -> Void

    var body: some View {
        Group {
            if let day = store.selectedDay {
                let transactions = store.transactions(onDay: day)
                if transactions.isEmpty {
                    ContentUnavailableView("No transactions", systemImage: "calendar")
                } else {
                    List {
                        ForEach(transactions) { transaction in
                            row(transaction)
                        }
                    }
                    .listStyle(.plain)
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

    private func row(_ transaction: Transaction) -> some View {
        // Every row taps into the form. Adjustments (created by Reconcile) open read-only there but
        // can still be deleted from the calendar (feat).
        Button {
            onEdit(transaction)
        } label: {
            TransactionRow(transaction: transaction)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(A11y.Calendar.txn(transaction.note))
    }
}
