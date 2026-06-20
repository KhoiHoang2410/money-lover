# Design Language: "Electric Lime Dark Fintech"

Extracted from the **PIFin** dashboard reference. A design-system brief for building
Money Lover's UI with the same vibe.

---

## The vibe in one line

> Premium dark-mode fintech — near-black canvas, one electric lime accent, generous
> rounded cards, big confident numbers, and selective "spotlight" cards (lime or white)
> that pop against the dark.

---

## What makes it work

- **High-contrast, low-color discipline.** Basically a 3-color system: charcoal surfaces
  + electric lime + white. No rainbow category colors. The restraint reads as "premium."
- **Accent inversion.** Most cards are dark, but 2–3 "hero" cards flip to solid lime or
  solid white. That inversion is the signature move — it directs the eye to balance,
  primary actions, and the upsell.
- **Soft, large radii + breathing room.** Everything is a rounded rectangle (~20pt) with
  comfortable internal padding. Nothing is cramped or boxy.
- **Numbers are the heroes.** Balances are huge and bold; labels are small and muted gray.
  Money is the content; typography reflects that.
- **Pill everything.** Nav tabs, percentage badges, profile chip, buttons — all fully
  rounded pills.

---

## Design tokens

| Token             | Value (approx)                                                        |
| ----------------- | --------------------------------------------------------------------- |
| Canvas / app bg   | `#0E0E10` near-black (reference has a navy→black gradient + blue glow) |
| Card surface (dark) | `#1C1C1E` / elevated `#242426`                                      |
| Accent (lime)     | `#C9F23B` (electric chartreuse)                                       |
| Hero light card   | `#F4F4EF` off-white                                                   |
| Text primary      | `#FFFFFF`                                                             |
| Text secondary    | `#8A8A8E` muted gray                                                  |
| Positive badge    | lime pill, dark text                                                  |
| Corner radius     | cards ~20–24, pills/buttons fully rounded                             |
| Font              | Geometric/neutral sans (Inter-like; on iOS → SF Pro / SF Pro Rounded) |
| Charts            | solid lime line/bars for primary, dashed white for comparison; minimal gridlines |

---

## Ready-to-use prompt

> **Design language: "Electric Lime Dark Fintech"**
>
> Build the Money Lover UI in this visual style:
>
> **Palette** — Near-black canvas (`#0E0E10`). Dark card surfaces (`#1C1C1E`, elevated
> `#242426`). One single accent: electric lime/chartreuse (`#C9F23B`). Off-white
> (`#F4F4EF`) for inverted hero cards. White primary text, muted gray (`#8A8A8E`)
> secondary text. **Strictly 3 colors — no multi-color category palettes.**
>
> **Accent inversion rule** — Keep most cards dark. Flip only 2–3 *hero* elements to solid
> lime or solid white: the total-balance card, the primary CTA, and one promo/upsell card.
> Lime cards use dark/black text. This inversion is the signature — use it sparingly to
> guide the eye.
>
> **Shape & spacing** — All surfaces are rounded rectangles, ~20–24pt corner radius.
> Generous internal padding, lots of breathing room. Pill shapes (fully rounded) for nav
> tabs, buttons, percentage badges, and chips. Soft, subtle shadows only.
>
> **Typography** — SF Pro / SF Pro Rounded. Money figures are large and bold (the visual
> hero of every card). Labels small, muted gray, medium weight. Strong size contrast
> between numbers and labels.
>
> **Data viz** — Minimal: no heavy gridlines, faint axis labels. Primary series in solid
> lime (line or rounded bars), comparison series as a dashed white line. One bar in a
> series can be highlighted lime to mark "today/selected." Small segmented icon-button
> toggles to switch chart types.
>
> **Components** — Stat cards = small muted label + tiny lime % badge top-right + huge bold
> value + sub-line delta ("+$529 vs last month"). Lists/tables = circular leading icon,
> title + timestamp/subtitle, right-aligned bold amount. Status shown as colored word
> ("Ready"/"Empty"), not a chip.
>
> **Overall feel** — Confident, premium, calm. Dark and quiet everywhere except the lime
> moments that demand attention. Money is the content; let the numbers and the single
> accent do the talking.
