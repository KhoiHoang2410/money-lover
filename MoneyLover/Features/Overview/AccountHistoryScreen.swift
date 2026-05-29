import SwiftUI

/// One account's transaction history with range / kind / search filters. A pushed destination —
/// builds its store in `.task` and carries no `NavigationStack` of its own.
struct AccountHistoryScreen: View {
    @Environment(\.modelContext) private var context
    let account: Source
    @State private var store: AccountHistoryStore?

    var body: some View {
        Group {
            if let store {
                content(store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard store == nil else { return }
            let newStore = AccountHistoryStore(account: account, transactions: TransactionRepository(context: context))
            newStore.load()
            store = newStore
        }
    }

    @ViewBuilder
    private func content(_ store: AccountHistoryStore) -> some View {
        @Bindable var store = store
        List {
            Section {
                Picker("Range", selection: $store.range) {
                    ForEach(HistoryRange.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)

                Picker("Kind", selection: $store.kind) {
                    Text("All").tag(TransactionKind?.none)
                    ForEach(TransactionKind.allCases) { Text($0.rawValue.capitalized).tag(Optional($0)) }
                }
            }
            Section {
                ForEach(store.entries) { transaction in
                    TransactionRow(transaction: transaction, showsDate: true)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.snappy, value: store.range)
        .animation(.snappy, value: store.kind)
        .searchable(text: $store.search, prompt: "Search notes")
        .overlay {
            if store.entries.isEmpty {
                ContentUnavailableView("No transactions", systemImage: "tray")
            }
        }
    }
}
