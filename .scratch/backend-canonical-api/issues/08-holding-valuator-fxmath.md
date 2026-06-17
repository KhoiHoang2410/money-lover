# 08 — HoldingQuantity, Valuator & TransferFxMath (pure, golden-tested)

Status: ready-for-agent
Depends on: 03, 04
References: PRD, ADR-0015, ADR-0010, CONTEXT.md (Holding, Invest, Transfer, Fee)

## Goal

Derive holding quantity from trades, value holdings/foreign accounts via resolved rates, and compute cross-currency transfer fees.

## Scope

- **HoldingQuantity**: live quantity = opening quantity + Σ Buys − Σ Sells (exact, non-float). Selling more than held is blocked (raise/return error result).
- **Valuator**: valuation = quantity × resolved rate; foreign-currency Account value = balance × resolved FX rate. Rate resolution is **override-aware** (per-user override wins over global; interface takes a resolved-rate provider so this module stays pure — the override/global resolution itself is issue 19).
- **TransferFxMath**: Fee = (amount out × manual rate) − amount in, expressed in destination currency, integer minor units, explicit rounding.

## Acceptance criteria

- Reproduces golden fixtures for quantity, valuation, and FX fee byte-identically.
- Negative-quantity sell is blocked exactly as the Swift `Core` does.
- Net worth conservation precondition holds: an Invest trade moves value between Account and Holding without creating/destroying value (verified fully in issue 09).

## Tests

- Golden-vector specs for quantity, valuation, FX fee.
- Unit: oversell blocked; fee rounding boundary cases match Swift.
