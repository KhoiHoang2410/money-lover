# 17 — Test fixtures & builders for the test-case catalog

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/`)

## What to build
Shared test data builders/fixtures that the new unit-test slices (issues 18–27) all build on, so amounts and entities aren't re-declared ad-hoc across suites. Per `docs/guidelines/testing.md`: test data via builders/fixtures (`AccountFixture`, `make(envelope:)`), amounts in `Money` minor units, `Date`/clock injected.

Provide builders for: Account/Holding/Credit-card Sources, Transactions of every kind (expense/income/transfer/adjustment, plus the Backfill `affectsBalance=false` flag), Envelopes (incl. Reserve) and AllocationTemplate, Goals with non-flat Schedules (incl. gap months), and a set of Rates (FX/gold/stock). Mirror the seed snapshot from `docs/testing/ui-test-scenarios.md` so unit and UI assertions line up.

## Acceptance criteria
- [ ] Builders cover Source (Account/Holding/Liability), every Transaction kind incl. Backfill flag, Envelope+Reserve, AllocationTemplate, Goal+Schedule (with gap months), Rate set.
- [ ] Amounts expressed in `Money` minor units; no float literals.
- [ ] A fixed/injected clock helper for date-dependent suites (GoalTracker, Signals, Calendar).
- [ ] Fixtures mirror the `ui-test-scenarios.md` seed snapshot (same accounts, envelopes, goal %s).
- [ ] Builders compile and are referenced by at least one new test in a follow-up slice.

## Blocked by
- None - can start immediately
