import SwiftUI

/// Previews each envelope's leftover heading into the Reserve, with an Apply action.
struct MonthEndSummary: View {
    let store: EnvelopesStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let outcome = store.monthEndOutcome()
        List {
            Section("Leftovers swept to Reserve") {
                ForEach(outcome.lines) { line in
                    HStack {
                        Label(line.envelope.name, systemImage: line.envelope.iconName)
                        Spacer()
                        Text(line.leftover.amount, format: .currency(code: line.leftover.currency.rawValue))
                            .foregroundStyle(line.leftover.isNegative ? Theme.Palette.bad : Theme.Palette.ok)
                    }
                }
            }
            Section {
                HStack {
                    Text("Reserve change").bold()
                    Spacer()
                    Text(outcome.reserveDelta.amount, format: .currency(code: outcome.reserveDelta.currency.rawValue))
                        .bold()
                        .foregroundStyle(outcome.reserveDelta.isNegative ? Theme.Palette.bad : Theme.Palette.ok)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            Button("Apply sweep") {
                store.applySweep()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Palette.pink)
            .padding()
        }
    }
}
