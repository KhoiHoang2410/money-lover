import SwiftUI

/// Appearance settings: the theme info, the color-scheme override, and the Reduce-motion
/// preference. Pushed from Config, so it carries no `NavigationStack` of its own.
struct AppearanceScreen: View {
    @AppStorage("reduceMotion") private var reduceMotion = false
    @AppStorage("appearance") private var appearance: AppearancePreference = .system

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
            }

            Section {
                Picker("Color scheme", selection: $appearance) {
                    ForEach(AppearancePreference.allCases) { option in
                        Text(option.label).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Color scheme")
            } footer: {
                Text("Money Lover is designed light-first. “System” follows your device; pick “Dark” to force dark mode.")
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
