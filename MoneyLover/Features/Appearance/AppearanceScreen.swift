import SwiftUI

/// Appearance settings: the (fixed) light theme info and the Reduce-motion preference.
/// Pushed from Config, so it carries no `NavigationStack` of its own.
struct AppearanceScreen: View {
    @AppStorage("reduceMotion") private var reduceMotion = false

    var body: some View {
        Form {
            Section {
                HStack(spacing: Theme.Spacing.md) {
                    RoundedRectangle(cornerRadius: Theme.Radius.tile)
                        .fill(Theme.heroGradient)
                        .frame(width: 56, height: 56)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gradient Rings")
                            .font(.subheadline.weight(.semibold))
                        Text("Light-first theme")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Theme")
            } footer: {
                Text("Money Lover uses a single light theme by design.")
            }

            Section {
                Toggle("Reduce motion", isOn: $reduceMotion)
            } footer: {
                Text("Skips decorative animations such as the goal-ring fill. The system Reduce Motion setting is always respected too.")
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceScreen()
    }
}
