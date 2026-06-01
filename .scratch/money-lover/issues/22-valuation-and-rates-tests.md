# 22 — Valuation & rates unit tests

Status: ready-for-agent

## Parent
`.scratch/money-lover/PRD.md` (test catalog: `docs/test-cases/01`, `16`, `19`)

## What to build
`Valuator` / `NetWorthEngine` / `RatePayloadParser` tests for converting every Source to base currency VND given a set of Rates, and for rate parsing/override/staleness. No network — parse against captured sample payloads and injected Rates.

## Acceptance criteria
- [ ] VND Account → identity; SGD/USD Account × FX → VND (01-04, 16-01).
- [ ] Gold Holding: chỉ uses per-chỉ price, lượng uses ×10; Stock = qty × HOSE price (16-02/16-03, 19-05).
- [ ] Net worth = Asset − Debt; Credit cards count toward Debt, not Asset (01-03).
- [ ] Missing/failed Rate → uses last-known with a staleness flag, never crashes/NaN (01-05, 19-03).
- [ ] Manual override beats the fetched rate and applies immediately; reverts when cleared (19-02/19-04).
- [ ] Payload parsing matches captured FX/SJC-gold/HOSE samples with correct unit conversions.

## Blocked by
- 17 — Test fixtures & builders
