import SwiftUI

/// The transactions for the calendar's selected day, shown inline below the grid in the space
/// the month leaves. Tapping a row opens it to edit or delete (Adjustments are Reconcile-owned and
/// not interactive here). Prompts to pick a day when nothing is selected.
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

    @ViewBuilder
    private func row(_ transaction: Transaction) -> some View {
        // Adjustments are created by Reconcile; they aren't hand-edited or deleted here. Everything
        // else taps into the edit form, which also carries a Delete action (feat 5).
        if transaction.kind == .adjustment {
            TransactionRow(transaction: transaction)
                .accessibilityIdentifier(A11y.Calendar.txn(transaction.note))
        } else {
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
}
