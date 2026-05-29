import SwiftUI

/// The review step of voice entry: the parsed expense, fully editable, confirmed before saving.
/// Source and envelope are confirmed here; saving is always an explicit, manual action.
struct VoiceReviewForm: View {
    @Bindable var store: VoiceEntryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            if !store.transcript.isEmpty {
                Section("Heard") {
                    Text(store.transcript)
                        .foregroundStyle(.secondary)
                }
            }
            Section {
                LabeledContent("Amount") {
                    TextField("Amount", value: $store.amountMajor, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section {
                Picker("From", selection: $store.sourceID) {
                    Text("Select…").tag(UUID?.none)
                    ForEach(store.sources) { source in
                        Text(source.name).tag(Optional(source.id))
                    }
                }
                Picker("Envelope", selection: $store.envelopeID) {
                    Text("None").tag(UUID?.none)
                    ForEach(store.envelopes) { envelope in
                        Text(envelope.name).tag(Optional(envelope.id))
                    }
                }
            }
            Section {
                TextField("Note", text: $store.note, axis: .vertical)
            }
            if let nudge = store.nudge {
                Section {
                    SignalCard(signal: nudge)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            Section {
                Button("Record again", action: store.reset)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save).disabled(!store.canSave)
            }
        }
    }

    private func save() {
        store.save()
        if store.didSave { dismiss() }
    }
}
