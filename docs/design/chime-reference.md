# Chime — design-language reference (study notes)

Source: Chime iOS on Mobbin (owner's logged-in session, free-tier sample of ~7 screens), captured for the calm-neobank re-skin ([ADR-0010](../adr/0010-visual-direction-calm-neobank.md)).

> **No Chime screenshots or assets are committed to this repo.** Chime's screens, logo, and illustrations are their IP. This file records the *patterns* we abstract from them — the design language, not the pixels. We build our own identity in the same family (ADR-0010: "Chime-adjacent, distinct").

## Screens studied
Home/balance, SpotMe, Direct-deposit setup, Credit Score, Chime+ perks comparison, splash, onboarding-flow index.

## Palette (observed, approximate)
| Role | Observation | Our distinct equivalent |
|------|-------------|-------------------------|
| Hero surface | Deep forest green, solid (no gradient) | Deep **pine-teal** (distinct from Chime's forest green) |
| Primary action | Vivid spearmint green (~#1EC677), full-width rounded button | **Emerald-teal**, deliberately deeper/cooler than Chime's hex |
| Soft accent | Pale mint promo cards (~#C9EAD9) | Pale mint, slightly cooler |
| Content bg | White / very light gray | Dynamic white (light) / near-black (dark) |
| Text | Near-black headings, mid-gray body | Ink + soft-ink neutrals |
| Score meter | Red→amber→green gauge | Keep our existing chart series, recolored |

## Layout & component patterns we adopt
1. **Flat surfaces.** Opaque cards on a plain background. No gradients on content, no glass on content (glass only on the system tab/nav bars — ADR-0010).
2. **Balance hero.** Large balance number on a solid deep-green panel; small label above; secondary stat as a quiet sub-line, not competing color blocks.
3. **Floating white cards over the hero.** A card can overlap the hero's bottom edge (e.g. the "Savings" card). Subtle, optional.
4. **Generous whitespace + strong type hierarchy.** Bold dark section titles, gray supporting copy, lots of breathing room. This is the single biggest driver of the calm feel.
5. **Full-width primary CTA.** One rounded-rect emerald button per screen for the main action; everything else is quiet/text.
6. **Linear progress, not rings.** Progress shown as horizontal bars inside cards (drives our `GoalRing` → bar swap).
7. **Flat list rows** with a small leading icon, title + subtitle, trailing value/chevron. Dividers are hairline, not boxes.
8. **Restraint with color.** Color is reserved for the hero, the primary CTA, and semantic states. Most of the UI is neutral.

## What we deliberately do NOT copy
- Chime's exact hexes, logo, wordmark, illustrations, mascot.
- Banking flows with no domain analog (send-to-person, direct deposit, ATM, credit-builder, KYC) — see ADR-0010.
- Dark-text-on-green buttons (Chime's choice); we use white-on-emerald for contrast clarity and to stay distinct.
</content>
