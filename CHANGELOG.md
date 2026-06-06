# Changelog

All notable changes to Money Lover are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/),
pre-1.0 simplified (see ADR-0008). Every PR adds an entry under its bumped version.

## [0.4.2] — Demo + AI verification

### Added
- **README demo** — an animated GIF walkthrough (Overview → Goals → Add transaction) plus a screenshot row, under a new `## Demo` section. Media lives in `docs/media/` and is captured on the iPhone 17 Pro simulator (iOS 26.5) by driving the seeded app through its stable [accessibility identifiers](MoneyLover/App/AccessibilityID.swift) — the same handles the XCUITest suite uses.
- **README `## Built & verified by AI`** — documents that the app is authored entirely by Claude and that every change runs the full gauntlet (TDD → CI build + unit + UI tests → AI PR review → versioned), with setup instructions for the `ANTHROPIC_API_KEY` secret.
- `.github/workflows/claude-review.yml` — on every PR (and on `@claude review` comments), Claude reviews its own diff against `CLAUDE.md`, the engineering/testing guidelines, the ADRs, and the money-correctness invariants, posting inline findings. Skips cleanly without the secret (forks never fail red).

### Changed
- README intro now states the project is built entirely by Claude and notes the personal-savings motivation behind it.

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
