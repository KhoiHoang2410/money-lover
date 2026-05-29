# 10 — Charts

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
A Charts screen (reached from Calendar and Config) with four trends: total balance over time, spending over time, spending per Envelope over time, and saving per Goal over time. The per-Envelope chart offers Last 7 days / 30 days / 6 months; 30d & 6m bars are scaled to an average-per-day; refuse with a clear message when history is insufficient for the chosen range. A "Save as screenshot" action (`ImageRenderer`).

## Acceptance criteria
- [x] Four charts render from real aggregated data (Swift Charts). — `TrendEngine` (balance/spending/saving) + `SpendingBucketEngine` (per-Envelope); views in `Features/Charts/`.
- [x] Range switch (7d/30d/6m) works; 30d/6m use average-per-day scaling; range/aggregation logic unit-tested. — `SpendBar.averagePerDay`; `SpendingBucketEngineTests`.
- [x] Insufficient-history → explicit refuse state, not misleading data; unit-tested. — `SpendingChartOutcome.insufficientHistory`; refuse view in `BucketSpendingChart`; tested.
- [x] "Save as screenshot" exports the chart via `ImageRenderer`. — `ChartsScreen.render` → `ImageRenderer` → `ShareLink`.

Note: code verified via build + 69 green Swift Testing tests + clean app launch. On-device visual confirmation of the Charts screen itself was not done this session (computer-use lacked macOS Accessibility/Screen-Recording grant; the iOS simulator skill needs `idb`, not installed). Recommend a quick manual look (Config → Charts & trends, and the Calendar toolbar chart button) before closing out.

## Blocked by
- 02 — Expense & Income
- 04 — Envelopes & template
- 08 — Goals
