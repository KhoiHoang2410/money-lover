# 16 — Accessibility & rotation pass

Status: ready-for-human

## Parent
`.scratch/money-lover/PRD.md`

## What to build
A cross-cutting quality pass over all screens: Dynamic Type (incl. large sizes), VoiceOver labels on every control (especially icon buttons and censored amounts), Reduce-Motion (swap large/ring animations for opacity), `accessibilityDifferentiateWithoutColor` for +/− day cells, stale badges, and ahead/behind indicators, portrait + landscape layout, and the bottom-inset audit so nothing hides behind the dock/FAB.

HITL: requires manual VoiceOver / Dynamic Type / rotation review on device.

## Acceptance criteria
- [ ] Every screen usable at the largest Dynamic Type size without clipping.
- [ ] VoiceOver reads every control with a meaningful label; icon-only buttons have text labels.
- [ ] Reduce-Motion path verified; color-only differentiators have a shape/icon fallback.
- [ ] All screens correct in portrait and landscape; no content hidden behind dock/FAB.

## Blocked by
- All feature slices (02–15)
