# Visual direction: Calm neobank (supersedes Gradient Rings)

Status: accepted — supersedes [ADR-0005](0005-visual-direction-gradient-rings.md).

The app's visual language moves from "Gradient Rings" (pink/yellow gradient hero, circular progress rings, dense tiles, floating dark dock) to a **calm neobank look**, studied from Chime's iOS app (Mobbin) but built as our own identity — not a clone. The defining moves:

- **Palette:** a Chime-*adjacent but distinct* green/teal primary (deliberately not Chime's exact spearmint hex), neutral grays, and semantic ok/warn/bad. Exact hexes are finalised in `Theme.swift` during the pilot PR, sampled from the reference and then shifted off-brand.
- **Surfaces:** flat, opaque content (cards, lists, sheets) like Chime. Only the **system tab bar and nav bars** keep iOS 26 Liquid Glass (the platform default) — "flat content, glass chrome".
- **Components:** Goal progress shown as **linear bars inside flat cards**, not circular gradient rings. `GoalRing` is retired or repurposed. The floating dark dock is dropped in favour of the native glass tab bar.
- **Information architecture:** features and flows are **unchanged** (Overview/Goals/Calendar/Add/Config and their sub-flows stay). We borrow Chime's *interaction patterns* only where a real domain analog exists (dashboard hero layout, move-money-style add sheet, detail-screen structure, empty states). Chime's banking flows (send-to-person, deposit, ATM, KYC) have no counterpart in our on-device envelope/holdings/goals model and are **not** imported.

## Why
The owner judged the Gradient Rings look too loud/AI-generic and wanted the restraint, hierarchy, and spacing discipline of a modern neobank. Chosen over (a) keeping Gradient Rings, (b) a literal Chime clone — rejected for IP/clone-perception risk and because copying a competitor's exact brand adds no product value — and (c) a fully Liquid-Glass-forward look, rejected as less aligned to the calm-flat reference.

## Consequences
- Re-skins **every screen** (~70 view files) and rewrites `Theme.swift` tokens. Hard to reverse — hence this record.
- Executed pilot-first: one reference screen (Overview) lands with the new tokens + ADR + screen inventory, signed off, then the rest fan out in themed PRs (ADR-0008 version bump per PR).
- A current-state screen inventory with screenshots lives at `docs/design/screen-inventory.md` as the before/after baseline and per-screen restyle worklist.
- Dark-mode variants of the new palette are required (the `appearance` preference already exists); they are defined alongside the light tokens in `Theme.swift`.
- Reference Chime screens are captured for **design study only** (Claude in Chrome on the owner's logged-in Mobbin session, a representative sample) — not redistributed, not pixel-copied, no third-party assets/logos imported.
