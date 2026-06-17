# 13 — Sources CRUD API (accounts, credit cards, holdings)

Status: ready-for-agent
Depends on: 02, 05, 07, 08
References: PRD, ADR-0017, CONTEXT.md (Account, Credit card, Holding)

## Goal

CRUD for money sources, returning live current balances and valuations.

## Scope

- `sources` schema (user-scoped): kind (account | credit card | holding), name, icon, currency, opening minor units; holding fields (opening quantity, unit, ticker); logo asset.
- Endpoints (extend OpenAPI YAML + conformance): `GET /sources`, `GET /sources/:id`, `POST /sources`, `PATCH /sources/:id`, `DELETE /sources/:id`.
- Responses via **roar-rails representers**, including computed current balance (BalanceEngine) and valuation (Valuator).
- **dry-validation** contracts on create/update (currency enum, holding requires quantity+unit, ticker for stock, etc.).
- Delete integrity: block or cascade per a stated rule when transactions reference the source (recommend block with a clear 409).

## Acceptance criteria

- CRUD works, user-scoped (issue 05 authorization enforced).
- Listed/read source includes correct current balance and valuation.
- Responses conform to the OpenAPI YAML; invalid params return structured 422.

## Tests

- Request specs for each verb, including authorization (cross-user 404) and validation (422) cases.
- Representer output-shape test; conformance assertions.
