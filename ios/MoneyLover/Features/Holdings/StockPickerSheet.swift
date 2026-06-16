import SwiftUI

/// A searchable list of bundled HOSE/HNX symbols. Picking one dismisses and reports it back.
struct StockPickerSheet: View {
    let onPick: (VNTicker) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var results: [VNTicker] { VNTickerList.matching(query) }

    var body: some View {
        NavigationStack {
            List(results) { ticker in
                Button {
                    onPick(ticker)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ticker.symbol).bold()
                            Text(ticker.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(ticker.exchange)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("stock.\(ticker.symbol)")
            }
            .searchable(text: $query, prompt: "Symbol or company")
            .navigationTitle("Pick stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
            }
        }
    }
}
