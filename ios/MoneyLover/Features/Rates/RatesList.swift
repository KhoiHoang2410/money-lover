import SwiftUI

/// Lists rates with auto/manual/stale state, pull-to-refresh, and tap-to-override.
struct RatesList: View {
    let store: RatesStore
    @State private var override: OverrideTarget?

    private struct OverrideTarget: Identifiable {
        let key: String
        var id: String { key }
    }

    var body: some View {
        List {
            ForEach(store.records, id: \.key) { record in
                Button {
                    override = OverrideTarget(key: record.key)
                } label: {
                    RateRow(record: record)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay {
            if store.records.isEmpty {
                ContentUnavailableView(
                    "No rates yet",
                    systemImage: "dollarsign.arrow.circlepath",
                    description: Text("Pull to refresh to fetch live FX, gold, and stock prices.")
                )
            }
        }
        .refreshable { await store.refresh() }
        .toolbar {
            Button("Refresh", systemImage: "arrow.clockwise") {
                Task { await store.refresh() }
            }
        }
        .sheet(item: $override) { target in
            RateOverrideSheet(
                key: target.key,
                current: store.records.first { $0.key == target.key }?.value ?? 0,
                onSave: { store.setManual(key: target.key, value: $0) }
            )
        }
    }
}
