import SwiftUI

/// The Input hub list of entry modes.
struct InputHub: View {
    let store: InputStore

    var body: some View {
        List {
            NavigationLink(value: InputRoute.expense) {
                Label("Expense", systemImage: "minus.circle.fill")
            }
            NavigationLink(value: InputRoute.income) {
                Label("Income", systemImage: "plus.circle.fill")
            }
            NavigationLink(value: InputRoute.transfer) {
                Label("Transfer", systemImage: "arrow.left.arrow.right")
            }
            NavigationLink(value: InputRoute.voice) {
                Label("Voice expense", systemImage: "mic.fill")
            }
            NavigationLink(value: InputRoute.reconcile) {
                Label("Update balances", systemImage: "checkmark.circle.badge.questionmark")
            }
            NavigationLink(value: InputRoute.backfill) {
                Label("Backfill", systemImage: "clock.arrow.circlepath")
            }
        }
        .overlay {
            if store.sources.isEmpty {
                ContentUnavailableView(
                    "Add a source first",
                    systemImage: "creditcard",
                    description: Text("Create an account or card in Config → Sources.")
                )
            }
        }
    }
}
