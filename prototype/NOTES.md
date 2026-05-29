# UI prototype — THROWAWAY

**Question:** What should Money Lover look like? Three radically different visual directions, pink/white/yellow, icon-heavy, tasteful animation, all 5 screens.

**Run:** `cd money-lover/prototype && python3 -m http.server 8765` → open http://localhost:8765
Switch direction: bottom bar arrows or ← →. Switch screen: top/bottom nav. `⟲ Rotate` previews landscape.

## The three directions

- **A — Soft Cards.** Pastel pink gradient, rounded soft cards, friendly big numbers, bottom tab bar + floating ⊕ FAB. Warm, approachable. Animation: floating FAB.
- **B — Bold Editorial.** High-contrast, huge display type, solid yellow/pink blocks, hard rules, segmented top nav. Confident, minimal-text, punchy.
- **C — Gradient Rings.** Pink→yellow gradient hero, progress rings for goals, dense tile/list dashboard, floating dark dock. Data-forward.

Structurally different: A = card stack/tabs, B = editorial type/segments, C = gradient dashboard/rings/dock.

## VERDICT

**Winner: C — Gradient Rings.** Pink→yellow gradient hero, goal progress rings, dense tile/list dashboard, floating dark dock. Data-forward, icon-heavy, tasteful. See `docs/adr/0005-visual-direction-gradient-rings.md`.

Prototype is throwaway — delete once the look is folded into SwiftUI.
