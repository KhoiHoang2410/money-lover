import SwiftUI

/// The Input hub list of entry modes.
struct InputHub: View {
    let store: InputStore

    var body: some View {
        List {
            NavigationLink(value: InputRoute.transaction) {
                Label("Add transaction", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier(A11y.Input.addTransaction)
            NavigationLink(value: InputRoute.reconcile) {
                Label("Update balances", systemImage: "checkmark.circle.badge.questionmark")
            }
            .accessibilityIdentifier(A11y.Input.reconcile)
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
