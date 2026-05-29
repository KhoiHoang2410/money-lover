import SwiftUI

/// A single recommendation, color- and icon-coded by severity. Reused on the Advice screen
/// and as the input-time nudge.
struct SignalCard: View {
    let signal: Signal

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: signal.kind.iconName)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: Theme.Layout.minTap, height: Theme.Layout.minTap)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(signal.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.ink)
                Text(signal.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Theme.Radius.tile))
    }

    private var tint: Color {
        switch signal.severity {
        case .info: Theme.Palette.yellowDeep
        case .warning: Theme.Palette.warn
        case .critical: Theme.Palette.bad
        }
    }
}
