import SwiftUI

/// Single source of truth for the app's visual language ("Calm neobank", ADR-0010).
/// All colors, spacing, radii, and timings live here — no magic numbers in views.
///
/// Direction: flat, opaque content surfaces; an emerald/pine palette studied from Chime but
/// distinct from it; color reserved for the hero, the primary CTA, and semantic states. Liquid
/// Glass is left to the system tab/nav bars only ("flat content, glass chrome").
enum Theme {
    enum Palette {
        // MARK: Brand (emerald-teal family — distinct from Chime's spearmint)
        /// Primary action / accent.
        static let primary = Color(hex: 0x0E9E74)
        /// Pressed / deeper accent and on-light emphasis.
        static let primaryDeep = Color(hex: 0x0A7D5B)
        /// Tinted fills, selection backgrounds, soft chips.
        static let primarySoft = Color(light: 0xD9F2E6, dark: 0x123E32)
        /// Deep pine-teal hero surface (solid — no gradient).
        static let hero = Color(hex: 0x0E3B30)
        /// Foreground used on top of `hero`.
        static let onHero = Color(hex: 0xF2FBF7)

        // MARK: Neutrals (dynamic light/dark)
        /// Screen background behind cards.
        static let background = Color(light: 0xF6F7F6, dark: 0x0B0F0D)
        /// Flat card / list-row surface.
        static let surface = Color(light: 0xFFFFFF, dark: 0x161B18)
        /// Secondary surface (grouped insets, pressed rows).
        static let surfaceAlt = Color(light: 0xEFF1F0, dark: 0x1E2421)
        /// Hairline dividers and card strokes.
        static let stroke = Color(light: 0xE7EAE8, dark: 0x2A322E)
        /// Primary text.
        static let ink = Color(light: 0x16201C, dark: 0xF1F4F2)
        /// Secondary text.
        static let inkSoft = Color(light: 0x6B7670, dark: 0x9BA8A1)

        // MARK: Semantic
        static let ok = Color(hex: 0x12A574)
        static let warn = Color(hex: 0xE0972B)
        static let bad = Color(hex: 0xE5484D)

        // MARK: Deprecated aliases (ADR-0005 "Gradient Rings" names)
        // Kept so un-restyled screens compile and recolor to the new palette automatically.
        // Removed per-screen as each is restyled in the fan-out PRs after the Overview pilot.
        @available(*, deprecated, message: "Use Palette.primary") static let pink = primary
        @available(*, deprecated, message: "Use Palette.primarySoft") static let pinkSoft = primarySoft
        @available(*, deprecated, message: "Use Palette.primaryDeep") static let pinkDeep = primaryDeep
        @available(*, deprecated, message: "Use Palette.warn") static let yellow = warn
        @available(*, deprecated, message: "Use Palette.primarySoft") static let yellowSoft = primarySoft
        @available(*, deprecated, message: "Use Palette.warn") static let yellowDeep = warn
        @available(*, deprecated, message: "Use Palette.stroke") static let line = stroke
    }

    /// Solid deep pine-teal hero fill (flat — replaces the ADR-0005 diagonal gradient).
    static let heroFill = Palette.hero

    /// Deprecated: the old loud pink→yellow hero gradient. Now a subtle near-solid emerald so
    /// any screen still referencing it recolors calmly until it is restyled. Prefer `heroFill`.
    @available(*, deprecated, message: "Use Theme.heroFill")
    static let heroGradient = LinearGradient(
        colors: [Palette.hero, Palette.primaryDeep],
        startPoint: .top,
        endPoint: .bottom
    )

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let tile: CGFloat = 14
        static let card: CGFloat = 18
        static let hero: CGFloat = 24
        static let bar: CGFloat = 6
    }

    enum Layout {
        /// Bottom inset every scrollable screen reserves so content clears the dock/FAB.
        static let bottomInset: CGFloat = 96
        /// Apple's minimum tap target.
        static let minTap: CGFloat = 44
    }

    enum Motion {
        static let standard: Animation = .smooth
        /// Eased reveal for progress fills (bars) on appear.
        static let reveal: Animation = .easeOut(duration: 0.5)
    }
}

// MARK: - Flat surfaces

extension View {
    /// A flat, opaque content card: surface fill, hairline stroke, rounded corners (ADR-0010).
    func flatCard(
        padding: CGFloat = Theme.Spacing.lg,
        radius: CGFloat = Theme.Radius.card
    ) -> some View {
        self
            .padding(padding)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(Theme.Palette.stroke, lineWidth: 1)
                    // Decorative border must not intercept taps on interactive card content.
                    .allowsHitTesting(false)
            )
    }
}
