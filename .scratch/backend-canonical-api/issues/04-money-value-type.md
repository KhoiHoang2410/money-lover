# 04 — Money value type (integer minor units)

Status: ready-for-agent
Depends on: 01
References: PRD, ADR-0015

## Goal

Provide the integer-minor-unit money primitive every engine and representer uses, so floats never enter money math.

## Scope

- A pure Ruby value object representing an amount as `{ minor_units: Integer, currency: Symbol }`.
- Operations needed by the engines: add/subtract (same-currency only, raises on mismatch), negate, compare, sum over a collection, and explicit conversion via a rate with **documented rounding** (used by Valuator and TransferFxMath).
- Currency enum (VND, USD, SGD) and unit handling for holdings (chỉ, lượng, share) as needed by quantity math (quantity is a separate exact type — `Rational`/`BigDecimal`-as-exact, never float).
- Representer/DB mapping helpers: minor-units `bigint` ↔ value object at the edge.

## Acceptance criteria

- No floating-point anywhere in the type; arithmetic is exact integer.
- Mixing currencies in add/subtract raises, not silently coerces.
- Conversion rounding is explicit and matches the rule used by the Swift `Core` (verified later via golden fixtures in dependent issues).

## Tests

- Unit tests: arithmetic, currency-mismatch raise, sum, rounding on conversion (boundary cases: .5 rounding direction matching Swift).
