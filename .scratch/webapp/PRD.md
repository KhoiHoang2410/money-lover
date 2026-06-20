# PRD: Money Lover Web App (Phase 2)

_Status: draft — derived via grill-with-docs against CONTEXT.md and ADRs 0013–0019._

## Problem Statement

Money Lover's money is now owned by the canonical Rails backend (ADR-0013); the only client today is the native iOS app, which is still on its pre-backend SwiftData build. There is no way to use Money Lover from a browser, and the architecture explicitly calls for a web client as a first-class delivery — built **after** the backend, **before** the iOS rewrite. The backend (issues 01–20) is complete, golden-tested, and exposes a hand-maintained OpenAPI contract; nothing consumes it from the web yet.

## Solution

A standalone single-page web app under `webapp/` that is a pure, online-only consumer of the Rails API (ADR-0018). It targets **full feature parity** with the backend surface — auth, money sources, transactions (expense/income/transfer/invest), envelopes & budgeting, goals & contributions, reconcile, net worth & reports, rate overrides, and signals — delivered in vertical slices. It holds no money data of its own and performs no money arithmetic; the backend remains the single source of truth (ADR-0013, ADR-0015). Visual language is "Electric Lime Dark Fintech" (ADR-0019), desktop-first and responsive to mobile-web, bilingual (en-US + vi-VN) from day one.

## Goals / Non-goals

**Goals**
- A browser client a User can register/log into and run their whole financial life from.
- Strict end-to-end typing against the OpenAPI contract; no hand-kept request/response shapes.
- Parity correctness: every money figure shown comes from the backend, never recomputed client-side.

**Non-goals (v1)**
- Offline write or a client-side money engine (ADR-0013).
- Visual consistency with iOS (ADR-0016 — divergence is intended).
- LLM phrasing / voice entry / on-device AI (paused project-wide, ADR-0013).
- Native mobile (iOS already owns that).

## User Stories

### Identity & access
- As a visitor, I can **register** a User with an email/username + password (creates a `password` Identity) and land logged in.
- As a User, I can **log in** and **log out**; my session survives a page reload without re-entering my password.
- As a User, I am the only one who ever sees my data; any attempt to read another User's row returns not-found, not the row.
- As a User, my **timezone** (from my account) drives month boundaries, "today", and resets shown in the UI.

### Money sources (Accounts, Cards, Holdings)
- I can see all my **Accounts** with their **Current balance** in their own currency.
- I can see my **Credit cards** as Liabilities (debt), and **Holdings** (Gold, Stock) with live quantity and their VND valuation.
- I can **create / edit / delete** an Account (opening balance + currency), a Credit card, and a Holding (opening quantity + unit; ticker for Stock).
- Foreign-currency Accounts and Holdings show both their native figure and the base-currency (VND) valuation the API returns.

### Transactions
- I can browse my **Transactions** filtered by source and by month, each showing its kind, amount, envelope, and date.
- I can record an **Expense** (assigned to an Envelope; reduces an Account or increases a Credit card's Liability).
- I can record an **Income** into an Account.
- I can record a **Transfer** between two of my own sources, including a **cross-currency** Transfer (amount out, amount in, manual Rate) — the **Fee** is computed and returned by the backend, never by the browser.
- I can record an **Invest** Buy/Sell (VND Account ↔ Holding) at the accepted unit price; selling more than held is blocked by the API and surfaced as a clear error.
- I can record a **Backfill** (a forgotten past Transaction); the UI explains that the source's Current balance is unchanged (ADR-0012).
- I can edit/delete a Transaction within the rules the API enforces (immutable kind/source where applicable).

### Envelopes & budgeting
- I can see my **Envelopes** with the current month's Allocation, spent, and remaining (from BudgetEngine).
- I can **create / edit / delete** Envelopes, mark exactly one as the **Reserve**, and seed **Starter envelopes**.
- I can **apply the Allocation template** to a month.

### Goals
- I can see my **Goals** with target, funding window, live balance (Σ Contributions), and the GoalTracker read-model: Expected-by-today, % ahead/delay, and each Schedule line's status (Funded/Due/Missed/Pending) + shortfall.
- I can **create / edit / delete** a Goal and its **Schedule**.
- I can record a **Contribution** from a VND Account into a Goal (a Transfer; net worth unchanged).

### Valuation & rates
- I can view the **Rates** resolving for me (global value or my override, with stale/overridden flags).
- I can **set / clear a manual override** for a rate; it affects only my valuations.

### Net worth & reports
- I can see my **net worth**: Asset (Accounts + Holdings + Goal balances) and Debt (Liabilities), in VND.
- I can view the report-data surfaces as charts: spending trends, envelope distribution, goal progress, and net-worth history — rendered in the lime/white minimal data-viz style.

### Reconcile
- I can enter **Reconcile** mode, re-enter each source's real balance, and submit; the API writes one signed **Adjustment** Transaction per drifted source atomically, and I see the resulting Adjustments + unchanged sources.

### Signals
- I can see my **Signals** (envelope pace, projected overspend, goal delay, shrinking Reserve, unusually large Expense) as the plain-text observations the backend returns — computed server-side, never in the browser.

## Implementation Decisions

### Architecture & boundaries (ADR-0018, ADR-0013)
- Static SPA: **Vite + React + TypeScript**, **react-router** for routing, **TanStack Query** for all server state (caching, refetch-on-focus/reconnect, loading/error/empty states), **openapi-fetch** as the typed HTTP client.
- The client imports `docs/api/generated/types.ts` (the contract types, ADR-0017) — request/response shapes are checked at compile time. No hand-written API types.
- No SSR; build is static assets. The browser is a dumb API consumer with an in-memory cache only — never a store of record.

### Money representation (ADR-0015, ADR-0013)
- **No client-side money arithmetic.** Display = format integer minor units → string via `Intl.NumberFormat` (`vi-VN`, ₫). Input = parse user text → integer minor units to POST. Quantities and rates are exact decimal **strings** end to end (never parsed to `number`).
- Every derived figure (Fee, remaining, net worth, shortfall, projection) is read from the API response. A small typed `Money`/`Quantity` display helper centralizes formatting/parsing; it does no math.

### Auth & session (ADR-0014)
- **Access token in JS memory; refresh token in a Secure, httpOnly, SameSite cookie** the backend sets. On 401 or reload, the SPA calls `POST /auth/refresh` (cookie sent automatically) to re-mint the access token; logout clears the cookie server-side. The refresh token is never reachable by JavaScript.
- **Backend precondition (blocking dependency):** the issue-06 auth endpoints currently return the refresh token in the JSON body and set no cookie. A backend follow-up must make `/auth/{register,login,refresh,logout}` `Set-Cookie` the refresh token and read it from the cookie (CORS `Access-Control-Allow-Credentials`, cookie attributes, and CSRF posture for the cookie path decided there). The web app cannot ship its session model until this lands.

### Internationalization (bilingual from day one)
- **en-US + vi-VN** locales. **Every fixed UI string** is wrapped as `t("<page>.<textName>")` — e.g. `t("money_transfer.transferAmount")` — never a hard-coded literal.
- Locale resources are authored as **YAML files** per locale, namespaced by page (`<page>.<textName>`). A language switcher lives in settings; default locale by browser preference, persisted per User.
- Money/number/date formatting is locale-aware (`vi-VN` grouping for ₫) and independent of the UI-copy locale. Domain units (`chỉ`, `lượng`, shares) render as-is.

### Visual & layout (ADR-0019)
- "Electric Lime Dark Fintech" tokens from `docs/design/electric-lime-dark-fintech.md`: near-black canvas, lime accent only, rounded cards, pill controls, accent-inversion for 2–3 hero elements, minimal lime/white charts. Strictly a 3-color system.
- **Desktop-first** (≥1024px multi-column dashboard with sidebar nav), responsive down to tablet (2-col) and mobile-web (1-col stacked cards, drawer nav). iOS owns native mobile.

### Information architecture (proposed)
- Top-level sections: **Dashboard** (net worth + signals + key cards), **Sources** (Accounts/Cards/Holdings), **Transactions**, **Envelopes**, **Goals**, **Reports**, **Reconcile** (mode), **Settings** (rates/overrides, timezone, language, logout).

### Contract consumption & error handling
- All reads/writes go through the typed client; the API's `{ error: { code, message } }` envelope maps to consistent toast/inline error UI. Validation errors (422) surface per-field where the contract allows.
- Optimistic UI is allowed for non-money state only; money figures always reflect the server response.

## Testing Decisions
- **Vitest + React Testing Library** for components/hooks; the typed client is mocked at the `openapi-fetch` boundary (typed fixtures derived from the contract).
- **Playwright** e2e for critical write flows (register/login → add expense → see balance change; transfer; contribution; reconcile), run against a seeded backend. Follows the project's e2e write-flow standard (cross-tab + relaunch where relevant; prove a regression test bites).
- **Type safety as a test**: `tsc --noEmit` against the generated contract is a CI gate; a contract bump that breaks the client fails the web lane.
- i18n lint: a check that no fixed copy is hard-coded (all strings via `t(...)`) and that en-US/vi-VN key sets match.

## Delivery Sequencing (full parity, sliced)
Parity is the v1 target, delivered as vertical slices so each merge is shippable:
1. **Foundation** — `webapp/` scaffold (Vite/React/TS, router, TanStack Query, openapi-fetch wired to generated types), design tokens, i18n harness (`t()` + YAML, en/vi), CI lane. *(Depends on the backend auth-cookie change.)*
2. **Auth + Dashboard** — register/login/logout/refresh; net worth + signals read.
3. **Sources** — Accounts/Cards/Holdings CRUD + valuation display.
4. **Transactions** — list/filter + Expense/Income, then Transfer (incl. cross-currency), Invest, Backfill.
5. **Envelopes** — CRUD, Reserve, starter, allocation template.
6. **Goals** — CRUD, Schedule, Contributions, tracker read-model.
7. **Reports + Rates** — charts, rate overrides.
8. **Reconcile** — the re-enter-balances flow.

(Each slice becomes a set of tracer-bullet issues under `.scratch/webapp/issues/` via the to-issues skill.)

## Dependencies / Preconditions
- **Backend auth-cookie support** (httpOnly refresh cookie + CORS credentials) — blocking for the session model (see Auth above).
- **CORS**: backend must allow the web origin with credentials.
- **Generated contract types** (`docs/api/generated/types.ts`) — already produced; the web build consumes them.
- Promote `docs/design/electric-lime-dark-fintech.md` to a tracked file (referenced by ADR-0019).

## Out of Scope (v1)
- Offline write / sync / conflict resolution (ADR-0013).
- Visual parity with iOS (ADR-0016).
- LLM phrasing, voice entry, on-device AI (ADR-0013).
- OAuth/Google login (Identity model supports it later; password-only for v1, ADR-0014).
- Native mobile app, push notifications, multi-user sharing.

## Further Notes
- ADRs introduced with this PRD: **0018** (web SPA stack), **0019** (web visual direction). Auth cookie behavior is already mandated by **0014**; only the backend implementation must catch up.
- Versioning is independent of iOS (ADR-0016); the iOS SemVer policy (ADR-0008) does not apply to `webapp/`.
