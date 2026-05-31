# Changelog

All notable changes to Money Lover are recorded here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/),
pre-1.0 simplified (see ADR-0008). Every PR adds an entry under its bumped version.

## [0.2.0] — Show app version

### Added
- App version + build shown in the Config footer (`Money Lover 0.2.0 (2)`), read from the bundle via `AppInfo`.
- Versioning policy: every PR bumps `MARKETING_VERSION` (SemVer, pre-1.0 simplified) and `CURRENT_PROJECT_VERSION` (`+1`). Documented in `CLAUDE.md`, `docs/guidelines/engineering.md` §13, and ADR-0008.
- `CHANGELOG.md` (this file).

## [0.1.0] — Initial

### Added
- Initial Money Lover app: net-worth overview, sources & balances, envelopes/budget, goals as funded assets, calendar, rates & prices, advice, voice expense entry, reconcile, and XCUITest suite.
