import SwiftUI

/// Single source of truth for the app's visual language (light-first "Gradient Rings", ADR-0005).
/// All colors, spacing, radii, and timings live here — no magic numbers in views.
enum Theme {
    enum Palette {
        static let pink = Color(hex: 0xFF5C8A)
        static let pinkSoft = Color(hex: 0xFFE3ED)
        static let pinkDeep = Color(hex: 0xE03E70)
        static let yellow = Color(hex: 0xFFC94D)
        static let yellowSoft = Color(hex: 0xFFF3D6)
        static let yellowDeep = Color(hex: 0xF0A500)
        static let ink = Color(hex: 0x241A1F)
        static let ok = Color(hex: 0x2BB673)
        static let warn = Color(hex: 0xF0A500)
        static let bad = Color(hex: 0xFF4D4D)
        static let line = Color(hex: 0xF1E8EC)
    }

    /// 160° pink → coral → yellow hero gradient.
    static let heroGradient = LinearGradient(
        colors: [Palette.pink, Color(hex: 0xFF8F6B), Palette.yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let tile: CGFloat = 18
        static let card: CGFloat = 24
        static let hero: CGFloat = 30
    }

    enum Layout {
        /// Bottom inset every scrollable screen reserves so content clears the dock/FAB.
        static let bottomInset: CGFloat = 96
        /// Apple's minimum tap target.
        static let minTap: CGFloat = 44
    }

    enum Motion {
        static let standard: Animation = .bouncy
        /// Eased reveal for progress fills (rings, bars) on appear.
        static let reveal: Animation = .easeOut(duration: 0.6)
    }
}
