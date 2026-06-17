# Ruby money engine, parity via shared golden vectors

The money engine (balances, budgets/sweep, goal tracking, valuation, reconcile, FX fees) is re-implemented in Ruby on the backend, with all amounts stored and computed as **integer minor units** (bigint) — never floats. To prevent silent divergence from the battle-tested Swift `Core`, correctness is pinned by **shared golden test vectors**: the existing Swift Core test cases are extracted into language-neutral fixtures (JSON), and CI asserts the Ruby engine produces byte-identical results.

## Considered options

- **Port Swift test vectors as shared golden fixtures (chosen).** Turns a risky rewrite into a verification exercise; the same fixtures can later guard any client-side recompute.
- **Fresh Ruby implementation with new RSpec tests.** Rejected: no guarantee it matches existing iOS behavior; divergence (rounding, FX fee, sweep) would surface in production on real money.

## Consequences

- Money-correctness invariants are the Definition of Done for the backend, mirroring the iOS DoD: current balance = opening + Σ transactions; holding quantity = opening + Σ buys − Σ sells; net worth conserved through transfers/contributions/invests.
- The golden fixtures become a shared artifact in the monorepo, owned alongside the glossary.
- No floating-point money anywhere; currency conversion and fee math operate on integer minor units with explicit rounding rules.
