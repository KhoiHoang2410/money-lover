# 15 — Config hub & Appearance

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
The Config tab as a hub wiring all sub-pages: Sources & balances, Envelopes & template, Goals & schedules, Rates & prices, Advice, Charts, and run-month-end-sweep. Plus an Appearance page (light theme info, Reduce-Motion toggle). Navigation via `NavigationStack` + `navigationDestination(for:)`.

## Acceptance criteria
- [ ] Config lists and routes to every sub-page via `navigationDestination(for:)` (no `NavigationLink(destination:)`).
- [ ] Appearance page exposes the Reduce-Motion preference and theme info.
- [ ] Onboarding (set opening balances) reachable.

## Blocked by
- 01 — Foundation & Sources
