# 18 — Net worth & report-data API

Status: ready-for-agent
Depends on: 02, 09, 14, 15, 16
References: PRD, CONTEXT.md (Asset, Debt), ADR-0017

## Goal

Expose net worth and the aggregated data behind the clients' reports and charts.

## Scope

- Endpoints (extend OpenAPI YAML + conformance):
  - `GET /net_worth` → assets, debt, net (NetWorth engine), in base currency.
  - Report-data endpoints (read-only aggregates) for: spending trends (monthly), bucket/envelope distribution, goal saving progress, balance/net-worth history over a date range. Shape them as data, not presentation.
- All user-scoped; date range params validated via dry-validation.

## Acceptance criteria

- `GET /net_worth` matches the NetWorth engine for fixture-derived states.
- Report endpoints return correct aggregates over a date range and are stable for client charting.
- Responses conform to the OpenAPI YAML.

## Tests

- Request specs: net worth correctness; each report aggregate over a known dataset; date-range filtering.
- Authorization, conformance.
