import SwiftUI

/// The Charts screen: four trend cards plus a "Save as screenshot" export. Pushed from the
/// Calendar and Config tabs, so it carries no `NavigationStack` of its own.
struct ChartsScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: ChartsStore?
    @State private var snapshot: Image?

    var body: some View {
        Group {
            if let store {
                ScrollView {
                    ChartsContent(store: store)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Layout.bottomInset)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if let snapshot {
                            ShareLink(
                                item: snapshot,
                                preview: SharePreview("Money Lover · Charts", image: snapshot)
                            ) {
                                Label("Save as screenshot", systemImage: "camera")
                            }
                        }
                    }
                }
                .task { render(store) }
                .onChange(of: store.range) { render(store) }
            } else {
                ProgressView()
                    .task {
                        let newStore = ChartsStore(
                            sources: SourceRepository(context: context),
                            transactions: TransactionRepository(context: context),
                            rates: RatesRepository(context: context),
                            envelopes: EnvelopeRepository(context: context),
                            goals: GoalRepository(context: context)
                        )
                        newStore.load()
                        store = newStore
                    }
            }
        }
        .navigationTitle("Charts")
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func render(_ store: ChartsStore) {
        let content = ChartsContent(store: store)
            .frame(width: 380)
            .padding(Theme.Spacing.lg)
            .background(Color(.systemBackground))
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        if let image = renderer.uiImage {
            snapshot = Image(uiImage: image)
        }
    }
}

#Preview {
    NavigationStack {
        ChartsScreen()
            .modelContainer(for: AppSchema.models, inMemory: true)
    }
}
