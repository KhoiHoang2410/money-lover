# 28 — UI / E2E test expansion (XCUITest)

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/00`, `01`, `02`, `03`, `05`, `07`, `09`, `16`, `20`)

## What to build
Extend the XCUITest suite for the UI-only behaviors that unit tests can't reach — gating, visibility, navigation, layout safety. Drive elements by stable `A11y` accessibility identifiers against the seeded sample data (`UITEST=1` reseed). Do NOT re-test arithmetic here; assert on-screen state only. Add a new `ConfigUITests` for the Config flows; extend existing suites otherwise.

## Acceptance criteria
- [ ] Layout safety: on every scrollable screen the last row/button is not hidden behind the floating dock/+ (00-04); FAB opens Expense directly (00-03).
- [ ] Overview amounts censored by default; eye toggle reveals/re-hides (01-01/01-02).
- [ ] Tapping an account opens its history; empty-state account shows a message, not a crash (02-01/02-03).
- [ ] Save/Record/Save gating + dismiss for Expense, Cross-currency transfer, Reconcile, Goal contribution (03-02/05-02/07-03/09-01) — the UI half of those flows.
- [ ] Bank logo renders from a local asset with no third-party logo network request (16-06).
- [ ] Config exposes every setup area; portrait↔landscape adapts without clipping/overlap (20-01/20-04).
- [ ] Any check blocked by a known defect is wrapped in `XCTExpectFailure` with a BUG-id.

## Blocked by
- None - can start immediately
