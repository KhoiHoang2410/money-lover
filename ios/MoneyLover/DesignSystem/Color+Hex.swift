import SwiftUI

extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xFF5C8A)`.
    /// Light-only for now; migrate to asset-catalog color sets when dark mode is added.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
