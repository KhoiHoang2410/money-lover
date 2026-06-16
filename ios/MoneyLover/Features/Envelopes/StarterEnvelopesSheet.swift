import SwiftUI

/// Picker for the hard-coded **Starter envelopes** set (feat 4). Entries whose name already exists
/// are shown disabled; the rest are multi-selectable, with a select-all / deselect-all toggle.
struct StarterEnvelopesSheet: View {
    let store: EnvelopesStore

    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<String> = []

    private var existing: Set<String> { store.existingNames }
    private var pickable: [StarterEnvelope] {
        StarterEnvelope.catalog.filter { !existing.contains(StarterEnvelope.key($0.name)) }
    }
    private var allPickableSelected: Bool {
        !pickable.isEmpty && pickable.allSatisfy { selected.contains($0.name) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(StarterEnvelope.catalog) { starter in
                        row(starter)
                    }
                } footer: {
                    Text("Pick the buckets you want. Greyed-out names already exist. Each is created with a ₫0 allocation you can set later.")
                }
            }
            .navigationTitle("Starter envelopes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(allPickableSelected ? "Deselect all" : "Select all") { toggleAll() }
                        .accessibilityIdentifier(A11y.Starter.selectAll)
                        .disabled(pickable.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { apply() }
                        .disabled(selected.isEmpty)
                        .accessibilityIdentifier(A11y.Starter.add)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ starter: StarterEnvelope) -> some View {
        let isExisting = existing.contains(StarterEnvelope.key(starter.name))
        Button {
            toggle(starter)
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: starter.iconName)
                    .frame(width: 24)
                Text(starter.name)
                Spacer()
                if isExisting {
                    Text("Added").font(.caption).foregroundStyle(.secondary)
                } else if selected.contains(starter.name) {
                    Image(systemName: "checkmark").foregroundStyle(Theme.Palette.ink)
                }
            }
        }
        .disabled(isExisting)
        .foregroundStyle(isExisting ? Color.secondary : Color.primary)
        .accessibilityIdentifier(A11y.Starter.row(starter.name))
    }

    private func toggle(_ starter: StarterEnvelope) {
        if selected.contains(starter.name) { selected.remove(starter.name) }
        else { selected.insert(starter.name) }
    }

    private func toggleAll() {
        if allPickableSelected { selected.removeAll() }
        else { selected = Set(pickable.map(\.name)) }
    }

    private func apply() {
        store.applyStarter(StarterEnvelope.catalog.filter { selected.contains($0.name) })
        dismiss()
    }
}
