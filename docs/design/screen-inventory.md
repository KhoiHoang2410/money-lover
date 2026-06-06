# Screen inventory

Baseline for the calm-neobank re-skin ([ADR-0010](../adr/0010-visual-direction-calm-neobank.md)). Every screen the app renders, its purpose, and the per-screen restyle note that drives the fan-out PRs after the Overview pilot.

**Legend — Chime analog:** does a Chime screen pattern map here? `direct` = clear analog, `partial` = borrow some patterns, `none` = our-domain-only (restyle to the language, no pattern to copy).

Screenshots: current-state captures live under `docs/design/screenshots/before/`. After the pilot, `after/` holds the restyled equivalents.

## Root navigation
Five tabs (`AppTab`): **Overview · Goals · Calendar · Add · Config**. The floating dark dock (ADR-0005) is replaced by the native iOS 26 Liquid Glass tab bar.

## Primary screens (tabs)

| # | Screen | File | Purpose | Chime analog | Restyle note |
|---|--------|------|---------|--------------|--------------|
| 1 | **Overview** | `Features/Overview/OverviewScreen.swift` | Net-worth hero with censor toggle; account/holding/goal rollup. The home tab. | direct (account-home / balance hero) | **PILOT.** Flat balance hero on tinted surface (no gradient), grouped account cards, generous whitespace. |
| 2 | **Goals** | `Features/Goals/GoalsScreen.swift` | Grid of savings goals with progress. | partial (savings/goals) | Replace gradient rings with linear progress bars in flat goal cards. |
| 3 | **Calendar** | `Features/Calendar/CalendarScreen.swift` | Per-day net grid, month nav, day detail. | none | Flat month grid, neutral day cells, accent only on today/selection. |
| 4 | **Add (Input hub)** | `Features/Input/InputScreen.swift` | Hub routing to Expense / Income / Voice / Reconcile entry. | partial (move-money sheet) | Adopt Chime "move money" sheet structure: large primary actions, flat list. |
| 5 | **Config** | `Features/Config/ConfigScreen.swift` | Settings hub → all sub-pages via `navigationDestination`. | direct (settings) | Standard grouped settings list; flat rows, section headers, no decorative gradient. |

## Secondary screens (pushed / presented)

| # | Screen | File | Purpose | Chime analog | Restyle note |
|---|--------|------|---------|--------------|--------------|
| 6 | **Goal detail** | `Features/Goals/GoalDetailScreen.swift` | Target/saved/expected, ahead-behind, schedule, add contribution. | partial | Bar-based progress header, flat schedule rows. |
| 7 | **Add goal** | `Features/Goals/AddGoalScreen.swift` | Create a goal + generated monthly plan. | partial (form) | Flat form, single accent CTA. |
| 8 | **Contribution sheet** | `Features/Goals/ContributionSheet.swift` | Fund a goal from a VND account (ADR-0007). | partial (amount entry) | Amount-first sheet, flat account picker. |
| 9 | **Calendar day detail** | `Features/Calendar/CalendarDayDetail.swift` | Transactions for a tapped day. | none | Flat transaction list. |
| 10 | **Month picker sheet** | `Features/Calendar/MonthPickerSheet.swift` | Year nav + 12-month grid. | none | Flat grid, accent on selection. |
| 11 | **Transaction / expense / income form** | `Features/Input/TransactionForm.swift`, `InputHub.swift` | Enter an expense/income/transfer. | partial (amount entry) | Amount-first, flat field stack, single CTA. |
| 12 | **Backfill form** | `Features/Input/BackfillForm.swift` | Enter past transactions. | none | Flat form. |
| 13 | **Voice entry** | `Features/Input/VoiceEntryScreen.swift` | Record → understand → review → save expense. | none | Flat review form; keep record affordance, restyle to accent. |
| 14 | **Reconcile** | `Features/Reconcile/ReconcileScreen.swift` | Re-enter real balances; drift → Adjustment. | none | Flat per-source rows, clear drift indication via semantic colors. |
| 15 | **Sources list** | `Features/Sources/SourcesScreen.swift` | Manage Accounts / Cards / Holdings. | direct (accounts list) | Flat grouped list with source icons. |
| 16 | **Add source** | `Features/Sources/AddSourceScreen.swift` | Add Account / Credit card / Holding + opening balance. | partial (form) | Flat segmented type picker + form. |
| 17 | **Account history** | `Features/Overview/AccountHistoryScreen.swift` | One account's history w/ range/kind/search filters. | direct (account activity) | Flat filter chips + transaction list. |
| 18 | **Envelopes list** | `Features/Envelopes/EnvelopesScreen.swift` | Budget envelopes + remaining. | partial (budgets) | Bar-based remaining per envelope, flat cards. |
| 19 | **Add envelope** | `Features/Envelopes/AddEnvelopeScreen.swift` | Create envelope + monthly allocation. | partial (form) | Flat form. |
| 20 | **Month-end** | `Features/Envelopes/MonthEndScreen.swift` | Month-end sweep summary into Reserve. | none | Flat summary, semantic colors for over/under. |
| 21 | **Charts** | `Features/Charts/ChartsScreen.swift` | Four trend cards + screenshot export. | partial (insights/spending) | Flat chart cards, recolored series to new palette. |
| 22 | **Rates** | `Features/Rates/RatesScreen.swift` | FX / gold / stock rates w/ override. | none | Flat rate rows. |
| 23 | **Rate override sheet** | `Features/Rates/RateOverrideSheet.swift` | Manually override a rate. | none | Flat amount sheet. |
| 24 | **Advice** | `Features/Advice/AdviceScreen.swift` | Rule-based signals, strongest first. | partial (insights cards) | Flat signal cards, semantic accenting. |
| 25 | **Appearance** | `Features/Appearance/AppearanceScreen.swift` | Theme info + color-scheme + reduce-motion. | direct (settings detail) | Flat grouped settings; update copy to new theme. |
| 26 | **Onboarding** | `Features/Onboarding/OnboardingScreen.swift` | First-run: add sources + opening balances. | partial (account setup) | Flat stepped setup, single accent CTA. |

## Shared components (DesignSystem)

| Component | File | Restyle note |
|-----------|------|--------------|
| `Theme` (tokens) | `DesignSystem/Theme.swift` | **Rewritten in this PR** — new palette (light+dark), flat card style, linear progress bar. |
| `TransactionRow` | `DesignSystem/TransactionRow.swift` | Flat row, amount via semantic color. |
| `AmountText` | `DesignSystem/AmountText.swift` | Keep; recolor to new semantic palette. |
| `IconPicker` | `DesignSystem/IconPicker.swift` | Flat grid. |
| `GoalRing` | `Features/Goals/GoalRing.swift` | **Retire / repurpose** — replaced by linear progress bar. |
| `NetWorthHeader` | `Features/Overview/NetWorthHeader.swift` | Reworked in pilot — flat hero, no gradient. |

## Notes
- Flows and information architecture are unchanged (ADR-0010): we restyle, and only borrow Chime *interaction patterns* where the `direct`/`partial` analogs above indicate.
- Chime reference (design study) captured separately; see `docs/design/chime-reference.md`.
</content>
</invoke>
