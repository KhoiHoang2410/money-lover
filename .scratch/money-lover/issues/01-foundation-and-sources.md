# 01 — Foundation & Sources

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
The app skeleton plus the Source domain end-to-end (the tracer bullet that establishes the MV + pure-services pattern). A SwiftUI app targeting iOS 26 with a `TabView` driven by a `Tab` enum (Overview, Goals, Calendar, Input, Config — placeholders for now), the `Theme` design-token enum (palette/spacing/radii/typography/animation/bottom-inset), the `Money` value type (integer minor units + currency), a SwiftData container with `…Record` models + a Repository that maps Record ⇄ pure domain types, and Source CRUD: add/list/edit Accounts, Credit cards (Liability), and Holdings (quantity + unit + ticker), each with an Opening balance. Bank Accounts show bundled logo assets; non-bank sources use an icon picker. Follows `docs/guidelines/engineering.md` and `docs/adr/0006`.

## Acceptance criteria
- [ ] App launches into a 5-tab shell using a `Tab` enum binding; rotation enabled.
- [ ] `Theme` holds all colors/spacing/radii/type/animation tokens + bottom dock-inset; no magic numbers elsewhere.
- [ ] `Money` is integer minor units + currency, with unit tests (arithmetic, currency-mismatch, no float drift).
- [ ] Sources persist via SwiftData; Repository maps Record ⇄ domain; round-trip mapping unit-tested.
- [ ] Can add/list/edit Account, Credit card, Holding with Opening balance; bank logos bundled (no runtime fetch); icon picker for others.
- [ ] Zero-warning build; `#Preview` on each view; one type per file.

## Blocked by
None - can start immediately.
