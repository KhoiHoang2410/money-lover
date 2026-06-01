# Changelog

All notable changes to Money Lover are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/),
pre-1.0 simplified (see ADR-0008). Every PR adds an entry under its bumped version.

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
