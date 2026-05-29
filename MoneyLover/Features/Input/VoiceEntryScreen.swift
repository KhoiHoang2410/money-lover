import SwiftUI

/// Voice expense capture: record → understand → review → save. A pushed destination in the
/// Input stack, so it carries no `NavigationStack` of its own and builds its store in `.task`.
struct VoiceEntryScreen: View {
    @Environment(\.modelContext) private var context
    @State private var store: VoiceEntryStore?

    var body: some View {
        Group {
            if let store {
                content(store)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Voice")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard store == nil else { return }
            let newStore = VoiceEntryStore(
                transcriber: SpeechTranscriberFactory.make(),
                parser: ExpenseParser(model: FoundationModelExpenseParser()),
                sources: SourceRepository(context: context),
                transactions: TransactionRepository(context: context),
                envelopes: EnvelopeRepository(context: context)
            )
            newStore.load()
            store = newStore
        }
    }

    @ViewBuilder
    private func content(_ store: VoiceEntryStore) -> some View {
        switch store.phase {
        case .idle, .recording:
            VoiceRecordView(store: store)
        case .parsing:
            ProgressView("Understanding…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .review:
            VoiceReviewForm(store: store)
        }
    }
}

#Preview {
    NavigationStack {
        VoiceEntryScreen()
    }
    .modelContainer(for: AppSchema.models, inMemory: true)
}
