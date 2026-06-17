# 14 — Transactions CRUD API (+ backfill, invest guard)

Status: ready-for-agent
Depends on: 02, 07, 08, 13
References: PRD, ADR-0017, ADR-0012 (backfill), ADR-0010 (invest), CONTEXT.md (transactions)

## Goal

CRUD for transactions across all kinds, with backfill atomicity and invest quantity safety.

## Scope

- `transactions` schema (user-scoped): kind (expense | income | transfer | invest | adjustment), amount minor units + currency, source/destination ids, cross-currency destination amount/currency + fee, note, envelope ref, goal ref, trade quantity + direction.
- Endpoints (extend OpenAPI YAML + conformance): `GET /transactions` (filters: date range, source, envelope, kind), `GET /transactions/:id`, `POST /transactions`, `PATCH`, `DELETE`.
- **Backfill**: a flag on create handled **atomically** — insert the transaction AND restate the source opening balance in one DB transaction so current balance is unchanged.
- **Invest**: Buy/Sell moves money Account↔Holding; **block oversell** (HoldingQuantity) before commit. VND-only invest.
- **Cross-currency transfer**: store amount out, amount in, manual rate; compute Fee via TransferFxMath.
- Editing/deleting recomputes affected balances (engine recompute on read keeps this consistent).
- dry-validation contracts per kind (required fields differ by kind).

## Acceptance criteria

- Each kind posts and affects the correct balances (verified against BalanceEngine).
- Backfill keeps current balance unchanged while appearing in history.
- Oversell is rejected atomically (no partial write).
- Responses conform to the OpenAPI YAML.

## Tests

- Request specs per kind; backfill invariant; oversell rejection; cross-currency fee correctness; filters.
- Authorization and validation specs; conformance assertions.
