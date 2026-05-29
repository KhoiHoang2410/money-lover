# 06 — Valuation (rates & prices)

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Value foreign-currency Accounts and Holdings in base VND. `PriceProvider` (Services) fetches FX (`open.er-api.com`), SJC gold (`edge-api.pnj.io`), and HOSE stock (`dchart-api.vndirect.com.vn`) per ADR-0003, with caching, a stale indicator, and a mandatory manual override. `Valuator` (pure) converts any Source/Holding to VND given a set of Rates. Config·Rates screen lists each rate with auto/manual/stale state and override.

## Acceptance criteria
- [ ] `Valuator.toBase` unit-tested: VND identity, SGD/USD × FX, gold ×1000/chỉ (×10 lượng), stock ×1000.
- [ ] `PriceProvider` parses each endpoint's payload (tested against captured fixtures with fakes).
- [ ] On fetch failure, last-known value is shown with a stale badge.
- [ ] Manual override is always available and wins over fetched values.
- [ ] Fetch happens on foreground/pull-to-refresh, not polling.

## Blocked by
- 01 — Foundation & Sources
