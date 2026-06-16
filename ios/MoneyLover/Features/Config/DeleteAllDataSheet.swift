import SwiftUI

/// Irreversible "Delete all data" confirmation. The destructive button stays disabled for a
/// `cooldown`-second think-time — its label counts the seconds down ("Confirm (3s)") and only
/// becomes tappable once the cooldown elapses. This forces a deliberate pause before an action
/// that cannot be undone.
struct DeleteAllDataSheet: View {
    /// Seconds the Confirm button stays disabled before it can be tapped.
    static let cooldown = 3

    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var remaining = DeleteAllDataSheet.cooldown

    private var isArmed: Bool { remaining <= 0 }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Theme.Palette.bad)
                    .accessibilityHidden(true)

                Text("Delete all data?")
                    .font(.title2.weight(.bold))

                Text("This permanently erases every account, transaction, envelope, goal, and saved rate. **This can’t be undone.**")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xl)

            Spacer()

            VStack(spacing: Theme.Spacing.md) {
                Button(role: .destructive) {
                    onConfirm()
                    dismiss()
                } label: {
                    Text(isArmed ? "Confirm" : "Confirm (\(remaining)s)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: Theme.Layout.minTap)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.Palette.bad)
                .disabled(!isArmed)
                .accessibilityIdentifier(A11y.Config.confirmDeleteAll)

                Button("Cancel") { dismiss() }
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: Theme.Layout.minTap)
            }
        }
        .padding(Theme.Spacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled()
        .task {
            // Live countdown; a fresh sheet always starts the full think-time.
            remaining = DeleteAllDataSheet.cooldown
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                remaining -= 1
            }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        DeleteAllDataSheet(onConfirm: {})
    }
}
