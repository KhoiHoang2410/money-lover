# PRD: Canonical Rails Backend & API (Phase 1)

Status: ready-for-agent

> Phase 1 of a three-track program (backend → webapp → iOS rewrite). This PRD covers **only** the backend and the API contract. The webapp and the iOS thin-client rewrite are separate, later PRDs written against the contract this phase produces.
>
> Governing decisions: ADR-0013 (canonical backend, thin clients), ADR-0014 (multi-tenant auth), ADR-0015 (Ruby money engine, golden parity), ADR-0016 (monorepo), ADR-0017 (OpenAPI contract-first). Glossary: `CONTEXT.md`.

## Problem Statement

Money Lover today is an on-device-only iOS app: the iPhone's local store is the only copy of a person's financial data, and there is no way to use the app from a browser, from a second device, or as more than one person. A user who wants to check or update their accounts from a laptop, or who replaces their phone, has no path. There is also no notion of an account a user logs into — the app assumes a single anonymous owner on one device.

## Solution

Stand up a canonical Rails + PostgreSQL backend that becomes the single source of truth for all money data, exposed as a JSON API. A user registers and logs in (username/password to start), and from then on their accounts, holdings, envelopes, goals, transactions, budgets, goal progress, valuations, and spending signals all live on the server and are reachable by any client. The same money rules the iOS app enforces today (balances, budgets, goal tracking, valuation, reconciliation, FX fees) are reproduced exactly on the server, so numbers never differ between the old app's logic and the new system. This phase ships no UI; it ships the API and the contract that the web and iOS clients will be built against.

## User Stories

### Identity & access

1. As a new user, I want to register with a username and password, so that I get a private space for my own money data.
2. As a returning user, I want to log in with my username and password, so that I can access my data from any client.
3. As a logged-in user, I want my session to stay valid without re-entering my password constantly, so that the app is convenient to use.
4. As a logged-in user, I want to log out, so that my refresh token is revoked and the device can no longer act as me.
5. As a security-conscious user, I want my access token to be short-lived and silently refreshed, so that a leaked access token has limited blast radius.
6. As a user, I want every request for my data to be authorized to me, so that no other user can ever read or change my accounts, transactions, envelopes, or goals.
7. As the product owner, I want the login system structured around pluggable identity providers, so that "Sign in with Google" can be added later as a new identity without a schema migration.
8. As a user in a specific timezone, I want the system to know my timezone, so that month boundaries, monthly resets, and "today" in signals are computed correctly for me.

### Accounts, cards, holdings (money sources)

9. As a user, I want to create an Account with a name, currency, opening balance, and icon, so that I can track a real bank balance or cash.
10. As a user, I want to create a Credit card as a Liability, so that card spending increases my debt without touching an Account until I pay the bill.
11. As a user, I want to create a Holding with an opening quantity and unit (gold in chỉ/lượng, stock in shares with a HOSE ticker), so that I can track something valued by quantity × market price.
12. As a user, I want to read a single source and its current balance, so that I can see where it stands now.
13. As a user, I want to list all my sources with their current balances and valuations, so that I can see everything at a glance.
14. As a user, I want to edit a source's name, icon, currency, or opening balance, so that I can correct setup mistakes.
15. As a user, I want to delete a source, so that I can remove something I no longer track (subject to integrity rules below).
16. As a user, I want each source's current balance to always equal opening balance + the sum of its transactions, so that the number I see matches reality.

### Transactions

17. As a user, I want to record an Expense against an Envelope from an Account or credit card, so that my spending reduces the right balance or increases the right debt.
18. As a user, I want to record Income into an Account, so that money received increases that Account.
19. As a user, I want to record a Transfer between two of my own sources, so that I can move money, pay a credit-card bill, or convert currency.
20. As a user, I want a cross-currency Transfer to record amount out, amount in, and a manual rate, so that the system computes and stores the Fee correctly.
21. As a user, I want to record an Invest Buy or Sell against a Holding, so that an Account pays/receives money and the Holding's quantity changes accordingly.
22. As a user, I want to be blocked from selling more of a Holding than I own, so that I cannot create an impossible negative quantity.
23. As a user, I want to record a Backfill — a forgotten past transaction — so that it appears in history while restating the source's opening balance so my current balance is unchanged.
24. As a user, I want to read, list, filter (by date range, source, envelope, kind), edit, and delete transactions, so that I can manage my ledger.
25. As a user, I want editing or deleting a transaction to recompute all affected balances, so that the ledger stays internally consistent.

### Envelopes & budgeting

26. As a user, I want to create, read, update, list, and delete Envelopes with a name, icon, and monthly Allocation, so that I can divide my money into buckets.
27. As a user, I want one Envelope to be the Reserve, so that month-end leftovers accumulate somewhere and do not reset.
28. As a user, I want to set optional weekly and monthly caps on an Envelope, so that I get a guardrail on a bucket's spending.
29. As a user, I want to see each Envelope's spent and remaining for the current month, so that I know how much budget is left.
30. As a user, I want to seed Starter Envelopes once, so that I can populate my list from a suggested set without duplicating envelopes that already exist by name.
31. As a user, I want to save an Allocation Template and apply it to a month, so that my default budget is set up automatically each month.
32. As a user, I want month-end leftovers to sweep into the Reserve (positive adds, overspend deducts), so that unused budget is preserved and overspend is accounted for.

### Goals

33. As a user, I want to create, read, update, list, and delete Goals with a name, target, icon, funding window, and Schedule, so that I can plan long-term savings.
34. As a user, I want to record a Contribution from a VND Account to a Goal, so that real money moves into the Goal as a Transfer and my net worth is unchanged.
35. As a user, I want to see a Goal's balance as the sum of its Contributions, so that progress reflects actual money put in.
36. As a user, I want to see each Schedule line's status (Funded, Due, Missed, Pending) and any shortfall, so that I know whether I am on track.
37. As a user, I want my Goal balance counted as an Asset in net worth, so that money saved toward goals is reflected in my totals.

### Valuation & rates

38. As a user, I want the backend to fetch and cache global FX, gold, and stock rates on a schedule, so that valuations use current market prices without me doing anything.
39. As a user, I want to set my own manual override for any rate, so that I can value a Holding or foreign Account at a price I choose.
40. As a user, I want my override to apply only to my valuations, so that it never affects other users.
41. As a user, I want a stale or failed fetch to fall back to the last cached rate, so that valuation still works when an upstream source is down.
42. As a user, I want all my totals expressed in the base currency (VND), so that I can read net worth as a single number.

### Net worth & reporting data

43. As a user, I want to read my net worth broken into assets, debt, and net, so that I understand my overall position.
44. As a user, I want net worth to be unchanged by a Contribution or an Invest trade, so that moving money between my own places does not look like a gain or loss.
45. As a user, I want endpoints that return the data behind spending trends, bucket distribution, goal progress, and balance history, so that clients can render reports and charts.

### Reconcile

46. As a user, I want to submit my real balances for my sources, so that the system creates Adjustment transactions for any differences.
47. As a user, I want each Reconciliation to be its own recorded action, so that the corrections are auditable.

### Signals

48. As a user, I want the backend to compute deterministic Signals (envelope pace, projected overspend, goal delay, shrinking reserve, large expense), so that I get spending insight.
49. As a user, I want Signals returned as plain text usable by any client, so that both web and iOS show the same advice.

### API & contract

50. As a client developer, I want a hand-maintained OpenAPI YAML describing every endpoint, so that I have an authoritative contract to build against.
51. As a web developer, I want TypeScript types generated from the OpenAPI YAML, so that my client is strictly typed against the real contract.
52. As a maintainer, I want CI to fail when the running API diverges from the OpenAPI YAML, so that the contract and the code never drift.
53. As a client developer, I want the API to accept and return JSON only and follow CRUD conventions (with domain actions modeled as createable resources), so that the API is predictable.
54. As a client developer, I want clear, validated error responses when my params are invalid, so that I can correct requests.

## Implementation Decisions

### Architecture & boundaries

- **Backend is canonical (ADR-0013).** PostgreSQL is the source of truth. This phase exposes a JSON-only HTTP API. No UI.
- **Pure domain core, mirrored from Swift `Core` (ADR-0015).** The money rules live in plain Ruby objects (POROs) with no Rails/DB dependencies, so they are unit-testable in isolation and can consume the shared golden fixtures. ActiveRecord models map rows ↔ domain value objects at the edge, analogous to the iOS Repository layer.
- **Layering:** Controller (thin) → dry-validation contract (params) → application service (orchestration, persistence, transaction boundaries) → pure domain module (money math) → representer (response). No money math in controllers or models.

### Money representation

- **Integer minor units everywhere** (`bigint` columns), never floats and never float-backed decimals. All arithmetic — including FX conversion and fee computation — operates on integers with explicit, documented rounding.

### Deep domain modules (pure, golden-tested)

- **Ledger / BalanceEngine** — current balance = opening + Σ balance-affecting transactions, per source. Single authority for "what is this balance".
- **HoldingQuantity + Valuator** — live quantity = opening + Σ buys − Σ sells; valuation = quantity × resolved rate (override-aware). Blocks negative quantity.
- **NetWorth** — assets = Σ(accounts + holdings + goal balances), debt = Σ liabilities, net = assets + debt, in base currency. Enforces conservation through transfers/contributions/invests.
- **BudgetEngine** — per-month envelope spent/remaining from the ledger, Allocation application, weekly/monthly caps, and Reserve carry/sweep (positive leftover adds, overspend deducts).
- **GoalTracker** — Schedule, Expected-by-today, per-line status (Funded/Due/Missed/Pending), and shortfall (Contributions fill lines oldest-first).
- **ReconcileService** — given submitted real balances, derive the Adjustment per source.
- **TransferFxMath** — Fee = (amount out × manual rate) − amount in, in destination currency.

### Action resources (non-CRUD operations as createable nouns, ADR-0017)

- `POST /reconciliations` → creates a Reconciliation, yielding Adjustment transactions.
- `POST /goals/:id/contributions` → creates a Contribution realized as a `.transfer` with `goal_id`, atomically debiting the VND Account and crediting the Goal.
- Allocation-template application → a createable resource that seeds a month's envelope allocations.
- Starter-envelope seeding → a createable resource that is idempotent on existing envelope names (case-insensitive, trimmed).
- **Backfill** → a flag on `POST /transactions` handled atomically server-side: insert the transaction *and* restate the source's opening balance in one DB transaction so current balance is unchanged.
- Month-end sweep → **deferred design decision**: either a stateful per-user-timezone job or derived-on-read from stored per-month allocation snapshots. Either way, the schema must record enough per-month allocation history to compute it, and `User.timezone` drives the boundary. Resolve during backend design before the envelope schema is frozen.

### Auth (ADR-0014)

- **Multi-tenant.** Every domain table carries a tenant scope (`user_id` or equivalent). Every read/write authorizes ownership; cross-tenant access is impossible, not merely discouraged.
- **`User` has-many `Identity`** = (provider, external id). `password` provider holds a password digest now; `google` is a future provider added as a new identity row, no migration. `User` carries a `timezone`.
- **TokenService** issues a short-lived JWT access token and a long-lived **rotating** refresh token. Refresh stored httpOnly-cookie on web, Keychain on iOS. Logout and refresh-rotation revoke prior refresh tokens.

### Rates (ADR-0013 supersedes ADR-0003's client-fetch)

- **RateService**: Sidekiq scheduled jobs fetch global FX/gold/stock rates and cache them in Postgres with a fetched-at timestamp; payload parsers convert upstream responses to integer-safe values. On fetch failure, the last cached value is served and flagged stale.
- **Per-user override** resolution: a user's override, when present, wins over the global cached rate for that user's valuations only.

### Signals

- **SignalEngine** (pure, ported from Swift) computes deterministic signals from the user's ledger/budgets/goals and returns plain text. No LLM, no voice (deferred, ADR-0004 paused).

### Rails conventions

- **JSON-only** request/response; reject non-JSON.
- **roar-rails representers** shape every response; no `to_json` on models in controllers.
- **dry-validation** contracts validate every endpoint's params and produce structured 422 errors.
- **CRUD** routing for resources; domain actions as the createable resources above.

### API contract (ADR-0017)

- **Hand-maintained OpenAPI YAML** is the source of truth, committed at the repo root docs area (shared, per ADR-0016).
- **TypeScript types are generated** from the YAML (consumed by the future webapp/iOS-contract tooling).
- **CI contract conformance test** asserts live API responses and accepted params conform to the YAML; drift fails the build.

### Schema (entities, not columns — columns finalized in backend design)

- `users` (with timezone), `identities` (provider, external id, password digest), refresh-token store.
- `sources` (account | credit card | holding; currency; opening minor units; holding quantity/unit/ticker), scoped to user.
- `transactions` (kind: expense | income | transfer | invest | adjustment; minor-unit amount + currency; source/destination; cross-currency destination amount/currency + fee; note; envelope ref; goal ref; trade quantity + direction), scoped to user.
- `envelopes` (name, icon, monthly allocation, reserve flag, optional caps, carried), with per-month allocation history sufficient for sweep.
- `goals` (name, icon, target, funding window, schedule), scoped to user.
- `rates` global (key, value, fetched-at, source) + `rate_overrides` per user.

## Testing Decisions

**What makes a good test here:** it asserts *external behavior* — given inputs (ledger, allocations, schedule, rates), the module returns the correct money result — never internal structure or private method calls. The pure domain modules are the priority because they are deep (lots of behavior behind a small interface) and carry all the money-correctness risk.

- **All pure money engines — golden vectors.** Ledger/Balance, HoldingQuantity/Valuator, NetWorth, BudgetEngine, GoalTracker, ReconcileService, TransferFxMath are tested against **shared golden fixtures extracted from the existing Swift `Core` test cases**, asserting byte-identical results. These fixtures are a shared monorepo artifact. This is the heart of ADR-0015 — the rewrite is a verification exercise, not a re-derivation.
- **TokenService + auth.** Unit-test JWT issue/verify, refresh rotation and revocation, and identity-provider resolution. Request-level tests assert authorization: user A cannot read or mutate user B's rows on any endpoint.
- **RateService + SignalEngine.** Payload parsers tested against captured upstream fixtures (no live network). Per-user override resolution unit-tested (override wins for the owner only; global fallback otherwise; stale fallback on failure). SignalEngine golden-tested against known ledgers.
- **API contract conformance.** A CI test asserts live responses and accepted params conform to the OpenAPI YAML. Representer output-shape tests assert the JSON structure clients depend on.
- **Prior art:** mirror the structure and coverage of the existing Swift `Core` test suite and the project's TDD discipline (`docs/guidelines/testing.md`). The golden fixtures literally come from that suite.

## Out of Scope

- The **webapp** and the **iOS thin-client rewrite** — separate PRDs, written against the contract this phase produces.
- The **new "Electric Lime Dark" visual design** — a client concern; not relevant to the API.
- **AI features** — voice-to-expense and LLM phrasing of signals are deferred (ADR-0004 paused). Only deterministic signal *text* is in scope.
- **Migration of existing on-device data** — fresh start; no import path.
- **Google / third-party login** — the schema is shaped for it (Identity providers) but only `password` ships now.
- **Per-user base currency** — base currency stays global VND for now.
- **Final month-end-sweep mechanism** — flagged as a deferred decision to resolve during backend design; only the requirement and the schema implication (per-month allocation history, user timezone) are fixed here.
- **Deployment / hosting / CI infra setup** beyond the contract-conformance test.

## Further Notes

- This PRD intentionally reverses ADR-0001; that ADR is marked superseded by ADR-0013.
- **Glossary collision to respect throughout:** "Account" means a money source; the login concept is "User" (with "Identity" for a login method). Do not name an auth model `Account`.
- The money-correctness invariants are the backend's Definition of Done, identical in spirit to the iOS DoD: current balance = opening + Σ transactions; holding quantity = opening + Σ buys − Σ sells; net worth conserved through transfers/contributions/invests; no negative holding quantity; no floating-point money.
- Build order for the program is backend → webapp → iOS rewrite; the existing iOS app keeps running on SwiftData untouched until its rewrite phase.
- Recommended first deliverable within this phase: the **OpenAPI YAML for core + action resources**, since both the conformance test and the client phases depend on it.
