import SwiftUI

/// First-run setup: add the accounts, cards and holdings you have today with their opening
/// balances. Presented automatically on first launch and reachable again from Config.
struct OnboardingScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var store: SourcesStore?
    @State private var addingSource = false

    var body: some View {
        NavigationStack {
            Group {
                if let store {
                    content(store)
                } else {
                    ProgressView()
                        .task {
                            guard store == nil else { return }
                            let newStore = SourcesStore(
                                sources: SourceRepository(context: context),
                                transactions: TransactionRepository(context: context)
                            )
                            newStore.load()
                            store = newStore
                        }
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ store: SourcesStore) -> some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    RoundedRectangle(cornerRadius: Theme.Radius.card)
                        .fill(Theme.heroGradient)
                        .frame(height: 72)
                        .overlay {
                            Image(systemName: "wallet.bifold.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                    Text("Add what you have today")
                        .font(.headline)
                    Text("Enter each account, card and holding with its current balance. That opening balance anchors every calculation — you can reconcile any drift later.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }

            Section("Your sources") {
                if store.sources.isEmpty {
                    Text("No sources yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(store.sources) { source in
                        LabeledContent(source.name, value: store.balance(for: source).formatted)
                    }
                }
                Button("Add a source", systemImage: "plus") { addingSource = true }
            }
        }
        .sheet(isPresented: $addingSource) {
            AddSourceScreen { source in
                store.add(source)
                store.load()
            }
        }
    }
}

#Preview {
    OnboardingScreen()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
