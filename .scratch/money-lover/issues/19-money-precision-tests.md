# 19 — Money precision unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/03`)

## What to build
`Money` value-type tests that lock down precision and validation: integer minor-units never drift, awkward sums (the 0.1 + 0.2 family) stay exact, zero/negative handled, currency mismatch rejected, formatting via FormatStyle with no float artifacts.

## Acceptance criteria
- [ ] 0.10 + 0.20 style sums are exactly 0.30 in minor units — no float drift (03-04).
- [ ] Zero amount and non-numeric input rejected at the value/parse layer (03-03).
- [ ] Adding/subtracting same currency correct; mixing currencies throws.
- [ ] Negative and zero amounts format and compare correctly.
- [ ] Table-driven (`@Test(arguments:)`) across representative amounts/currencies (VND, USD, SGD).

## Blocked by
- 17 — Test fixtures & builders
