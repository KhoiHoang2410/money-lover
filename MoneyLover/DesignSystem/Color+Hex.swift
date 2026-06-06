import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Creates a color from a 24-bit RGB hex value, e.g. `Color(hex: 0xFF5C8A)`.
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// A dynamic color that resolves to `light` in light mode and `dark` in dark mode.
    /// Used by `Theme` neutrals so the calm-neobank palette adapts to both schemes (ADR-0010).
    init(light: UInt, dark: UInt) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
        #else
        self.init(hex: light)
        #endif
    }
}
