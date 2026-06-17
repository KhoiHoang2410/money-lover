# 03 — Shared golden fixtures from Swift Core

Status: ready-for-agent
Depends on: 01
References: PRD, ADR-0015

## Goal

Extract the existing Swift `Core` money-logic test cases into language-neutral golden fixtures that the Ruby engines (issues 07–12) assert against byte-identically.

## Scope

- Identify the Swift `Core` test suites covering balances, holding quantity/valuation, net worth, budgets/sweep, goal tracking, reconcile, and FX fees (in `ios/MoneyLover/...`).
- Produce **JSON golden fixtures** in a shared monorepo location (e.g. `docs/api/golden/` or a top-level `golden/`), each fixture = `{ inputs, expected_outputs }` in integer minor units, independent of any language.
- Where the Swift tests embed scenarios in code, transcribe them faithfully — same inputs, same expected results. Do not invent new numbers; this is a transcription, not a re-derivation.
- Add a tiny loader spec on the iOS side (optional) or a checksum so fixtures can't silently drift from the Swift cases they came from.

## Acceptance criteria

- One fixture set per engine area, covering the same cases the Swift suite covers (including edge cases: cross-currency fee rounding, overspent reserve sweep, oldest-first shortfall, negative-quantity block).
- Fixtures are pure data (no Ruby/Swift), consumable by both languages.

## Tests

- A fixture-integrity check (schema-validate each fixture; values are integers where money is expected).
