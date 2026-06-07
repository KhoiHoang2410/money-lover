# Changelog

All notable changes to Money Lover are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/),
pre-1.0 simplified (see ADR-0008). Every PR adds an entry under its bumped version.

## [0.8.0] — Backfill is a normal transaction

### Added
- **Backfilled toggle on the add-transaction form (feat):** the calendar `+` Expense/Income form now has a **Backfilled** switch for logging a forgotten *past* entry. The last choice is remembered for the next new transaction (`@AppStorage`, the existing `txn.default.*` convention).

### Changed
- **Backfill is now an ordinary transaction (feat, ADR-0012):** a backfilled entry shows on the **calendar** and in history and counts toward envelopes/trends/signals like any other transaction. Its account's **current balance stays unchanged** because the entry's **opening (beginning) balance** is restated by the offsetting amount when it's recorded. Previously a backfill was *informational* (`affectsBalance == false`) and was invisible on the calendar grid. The `affectsBalance` flag is removed entirely, and the two writes commit in a single save so observing screens reload one consistent state.
- **Backfill consolidated into the add-transaction form (feat):** the standalone Backfill screen (Add → Backfill) is removed; the toggle replaces it.

### Fixed
- **Backfilled expenses now count toward their envelope (feat):** an envelope-assigned backfill reduces that envelope's remaining like any expense (previously the known TC-08-04 defect — now intended behaviour).

## [0.7.0] — Editable balances & caps, adjustment delete, data backup

### Added
- **Edit sources & holdings (feat):** tap a row in Config → Sources or Config → Holdings to edit it in place — including updating an account/card's **opening balance** or a holding's **opening quantity**. The forms reuse the add screen, pre-filled.
- **Auto-seed rates for new currencies/holdings (feat):** adding a non-VND Account, or a gold/stock Holding, now inserts a placeholder rate (`fx.<CUR>`, `gold`, or `stock.<TICKER>`) so it appears on Config → Rates immediately for the owner to fill in or refresh. Pure `RateKeys` maps a `Source` to its required keys.
- **Envelope caps (feat):** tap an envelope to edit it — adjust its allocation plus optional **cap per week** and **cap per month**. Rows show this week's / this month's spend against the cap, turning red with a warning glyph when reached (`EnvelopeCapEngine`, accessibility-safe).
- **Backup & restore (feat):** Config → Backup exports all data to an iOS-friendly `.json` file (Files/iCloud Drive) and re-imports one to replace the current data, via `DataBackup` + `BackupRepository`.

### Changed
- **Delete reconcile Adjustments from the calendar (feat):** a day-detail Adjustment row now opens a read-only view with a Delete action, so a balance fix posted by Update balances can be removed (previously non-interactive).

### Fixed
- **Clear all data now refreshes immediately (feat):** the DEBUG "Clear all data" deleted records via a batch delete whose `save()` posted no `didSave`, so screens kept stale rows until relaunch. It now deletes per-record, firing the change notification that reloads every store.

## [0.6.0] — Transaction form improvements

### Added
- **Icons in the From/Into/Envelope/Holding pickers:** the Add-transaction and Backfill forms now show each source's bundled bank/brand logo (or its SF Symbol) and each envelope's icon inline in the menu pickers, so options are recognizable at a glance, not just by name.
- **Remembered picker defaults:** the form prefills the last-committed From/Into account, transfer From/To, invest account, and envelope for the next *new* transaction (per kind), and updates that default whenever you save with a different pick. Editing an existing transaction never changes the remembered defaults.
- **"OK" keyboard accessory:** every amount/number/note field in the Add-transaction and Backfill forms now shows an **OK** button above the keyboard to accept the value and dismiss the keyboard (the decimal pad has no return key).

### Fixed
- **Backfill amount grouping:** the Backfill amount field now groups thousands live as you type (e.g. `1,000,000`), matching the Add-transaction field, instead of showing the raw digits until commit.

## [0.5.0] — Holdings & investing, calendar editing, starter envelopes, voice removal

This version covers a feature batch delivered across several PRs; per request it carries the batch's single version bump.

### Added
- **Holdings & Invest (ADR-0010):** a dedicated Holdings screen (Config → Holdings) adds gold/stock by **quantity only** (no money field), with a bundled offline HOSE/HNX symbol picker. A new **Invest** transaction type Buys/Sells units of a Holding from a VND Account at a manual unit price; a Holding's live quantity = opening quantity + Σ Buys − Σ Sells, valued at the market Rate. Selling more than held is blocked.
- **Calendar floating + (feat 1):** add a transaction on the picked day (else today) via the same merged form.
- **Edit / delete from the calendar (feat 5):** tap a day-detail row to edit it in place or delete it, gated by a new **"Ask before deleting"** setting (Config → Appearance, default off). Adjustments stay Reconcile-owned.
- **Starter envelopes (feat 4):** seed the Envelopes list from a curated set (name + icon, ₫0 allocation) with existing-name disabling, select-all / deselect-all, and Reserve auto-assignment when none exists.

### Changed
- `TransactionRepository` gained `update`/`delete`; balances and holding quantities are derived from the ledger.

### Removed
- **Voice expense:** the voice-entry UI, on-device speech transcription, and the microphone/speech-recognition usage strings are removed. The text expense parser is retained for future reuse.

## [0.4.1] — Security automation

### Added
- `.github/dependabot.yml`: daily (00:00 `Asia/Ho_Chi_Minh`) grouped PRs for the `github-actions` ecosystem — security **and** version updates. These PRs run `ci.yml`. The `swift` ecosystem is shipped commented-out until a `Package.swift` exists.
- `.github/workflows/security-scan.yml`: daily + manual gitleaks (secrets, full history) and Trivy (dependency vulns) scan on ubuntu. Never opens a PR; upserts a single sticky issue labelled `security-scan` and auto-closes it on a clean run.

### Changed
- `ADR-0008` amended: bot-authored dependency/security PRs are exempt from the version + changelog bump, and the scan workflow reports issues rather than self-opening PRs (only Dependabot opens PRs, and those run CI).

## [0.4.0] — Grouped amount entry

### Added
- Amount fields in **Add transaction** (amount / amount-out / amount-in) and **Add source** (opening balance) now show locale grouping separators live as you type (e.g. `1.000.000`), matching the Overview's display format. Driven by the pure, locale-aware `AmountInputFormatter` (regroups every keystroke, keeps the bound `Decimal` exact, respects each currency's fraction digits).
- `AmountInputFormatterTests`: grouping per locale separator, idempotency under re-feed, leading-zero handling, fraction truncation (incl. VND's zero-fraction rule), and display⇄value agreement.

### Changed
- Add-transaction amount fields switched from `TextField(value:format: .number)` to a grouped `TextField(text:)` binding; the Rate field stays `.number`. The opening-balance field re-groups when the selected currency changes.

## [0.3.0] — Cross-tab freshness fix + Effect-Contract e2e tests

### Fixed
- Read-models went stale after a write in another tab (adding a cash expense did not reduce Cash or appear on the calendar until relaunch). Stores now observe `ModelContext.didSave` and re-derive, retiring the per-screen `.onAppear { load() }` band-aids (ADR-0009).

### Added
- `ADR-0009`: read-models stay fresh by observing the ModelContext.
- `docs/test-cases/EFFECT-CONTRACT.md`: cross-tab freshness + relaunch contract layered over the catalog; the `Automation:` lines of TC-03/05/06/07/08/09/11/15 now point at the new tests.
- Effect-Contract XCUITests, each proven to fail without the fix (negative control): `AddExpenseUITests.testExpensePropagatesAcrossTabsAndSurvivesRelaunch`, `TransferUITests`, `CrossCurrencyTransferUITests.testCrossCurrencyTransferChangesNetWorthByFee`, `GoalContributionUITests.testContributionKeepsNetWorthAndReducesFundingAccount`, `ReconcileUITests.testReconcileAdjustsBalanceAndNetWorth`, `BackfillUITests`, `IncomeUITests`, `EnvelopesUITests`.
- `InputStoreTests` (store reload contract); `ModelChangeObserver`; the calendar-day a11y id (defined but unused); `UITEST_PRESERVE` relaunch hook; shared assertion helpers.

## [0.2.4] — Engine & E2E test gap-fill (issues 25–33)

### Added
- `BudgetEngineMonthEndTests`: `monthEnd` determinism — identical envelopes + spend yield identical `reserveDelta`/leftovers (TC-12-05, engine-reachable portion).
- `ReconcileServiceTests`: multi-source reconcile — exactly one signed Adjustment per *changed* source, `nil` for unchanged, `sourceID` preserved (TC-07-04).
- `SignalEngineTests`: table-driven pace threshold across Feb/Apr/May lengths and days-of-month, asserting the engine's exact integer rule `spent·daysInMonth > allocation·day` incl. the strict-equality boundary (TC-13).
- `ValuatorTests`: explicit SGD→VND conversion; missing FX / unknown ticker / zero gold price all degrade to ₫0 — no crash or NaN (TC-01-05/16-01/19-03).
- `NetWorthEngineTests`: multiple credit cards aggregate into Debt; mixed-currency net via rates (TC-01-03).
- `RatesRepositoryTests` (new, in-memory SwiftData): manual override beats a later successful fetch and reverts to the fetched value once cleared; non-overridden keys still update (TC-19-02/19-04).
- `TransferEngineTests`: negative cross-currency Fee when received exceeds expected returns the exact signed value, never clamped/thrown (TC-05-05).
- `SpendingBucketEngineTests`: per-Envelope buckets emit an independent series each, so each row scales to its own max (TC-18-04).
- `CalendarMathTests`: foreign-currency entries excluded from per-day net (VND-only calendar) (TC-17).
- `ConfigUITests` (new XCUITest): every Config area reachable (Sources/Envelopes/Rates/Month-end/Charts/Advice/Appearance) and the list survives portrait↔landscape rotation (TC-20-01/20-04).

### Known issues / deferred
- Issue 25 "template application": no `AllocationTemplate` apply API exists — the template *is* the Envelope set (per `Fixtures.swift`); deferred to a feature issue, not a test gap.
- Month-end idempotency (TC-12-05, store level): `EnvelopesStore.applySweep`/`sweepIntoReserve` track no last-swept boundary, so a repeat run would double-credit the Reserve — a real defect, not test-coverable as a guarantee. Filed as a follow-up.
- Issue 33 criteria 1 & 5 (bank-logo source / layout-behind-dock) not automatable: the bank-logo image and floating dock/+ carry no accessibility identifiers; `config.charts`/`config.advice` ids are declared but not wired to their rows. Needs A11y ids in production first.

## [0.2.3] — Balance correctness unit tests

### Added
- `BalanceCorrectnessTests`: catalog-mapped, fixture-based money-correctness suite asserting through `BalanceEngine`/`NetWorthEngine`/`BudgetEngine` — credit-card Expense raises Liability with Accounts untouched (04-01/04-03), same-currency Transfer and card bill payment net to zero on net worth (06-01/06-02/06-03), Backfill excluded from current balance and net worth (08-01/08-02), Income raises the Account and leaves Envelopes untouched (15-01/15-02), plus empty→opening, mixed-kind sums, signed Adjustments, and source isolation.

### Known issues
- TC-08-04: a Backfill (`affectsBalance=false`) expense assigned to an Envelope is still counted by `BudgetEngine.spent` (filters only on `kind`/`envelopeID`), so it leaks into Envelope remaining. Documented via `withKnownIssue`; `BalanceEngine` itself excludes it correctly.

## [0.2.2] — Money precision unit tests

### Added
- `MoneyTests` precision/validation lock-down (`MoneyLoverTests/MoneyTests.swift`): table-driven minor↔major round-trips and `Money(major:)` rounding across VND/USD/SGD, the 0.1+0.2 family staying exact in minor units, zero/negative handling, currency-mismatch rejection, a parse-layer floor for non-numeric input, and locale-independent FormatStyle stability. Catalog TC-03-03/03-04.

## [0.2.1] — Test fixtures & builders

### Added
- Shared test fixtures (`MoneyLoverTests/Support/Fixtures.swift`): named seed-snapshot presets (`Fixtures.mbBank`, `.goldSJC`, `.houseGoal`, `.standardRates`, …) plus parameterized `make…` builders for sources, every transaction kind (incl. Backfill `affectsBalance=false`, cross-currency transfer, contribution, adjustment), envelopes + Reserve, goals with gap-month schedules, and a rate set. Amounts in `Money` minor units; deterministic GMT `date(_:_:_:)` helper for date-dependent suites.
- `FixturesTests` exercising the builders against the Core engines.

## [0.2.0] — Show app version

### Added
- App version + build shown in the Config footer (`Money Lover 0.2.0 (2)`), read from the bundle via `AppInfo`.
- Versioning policy: every PR bumps `MARKETING_VERSION` (SemVer, pre-1.0 simplified) and `CURRENT_PROJECT_VERSION` (`+1`). Documented in `CLAUDE.md`, `docs/guidelines/engineering.md` §13, and ADR-0008.
- `CHANGELOG.md` (this file).

## [0.1.0] — Initial

### Added
- Initial Money Lover app: net-worth overview, sources & balances, envelopes/budget, goals as funded assets, calendar, rates & prices, advice, voice expense entry, reconcile, and XCUITest suite.
