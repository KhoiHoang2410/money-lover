import SwiftUI

/// The owner's app-level color-scheme preference, set on the Appearance screen.
/// Money Lover is light-first (ADR-0005): `.system` follows the device, while `.light` and
/// `.dark` force a scheme. Persisted via `@AppStorage("appearance")`.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// The scheme to force on the view tree, or nil to follow the device setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
