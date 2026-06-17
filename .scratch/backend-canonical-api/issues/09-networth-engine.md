# 09 — NetWorth engine (pure, golden-tested)

Status: ready-for-agent
Depends on: 07, 08
References: PRD, ADR-0015, ADR-0007, CONTEXT.md (Asset, Debt, Goal)

## Goal

Compute assets, debt, and net worth in base currency, enforcing the conservation invariants.

## Scope

- Pure module: **assets** = Σ(Account values + Holding valuations + Goal balances), **debt** = Σ liabilities, **net** = assets + debt, all converted to base currency (VND) via resolved rates.
- Goal balance = Σ Contributions (a Goal is a funded asset, ADR-0007).
- Enforce/verify: net worth is **unchanged** by a Contribution (Account ↓, Goal ↑) and by an Invest trade (Account ↔ Holding).

## Acceptance criteria

- Reproduces net-worth golden fixtures byte-identically.
- Conservation tests pass: applying a Contribution or Invest to a fixture state leaves net unchanged.

## Tests

- Golden-vector spec for assets/debt/net across multi-currency fixtures.
- Property/unit: Contribution and Invest preserve net worth.
