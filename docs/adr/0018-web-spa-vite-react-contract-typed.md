# Web client is a Vite + React SPA typed off the OpenAPI contract

The `webapp/` client (ADR-0013 Phase 2) is a single-page application built with Vite + React + TypeScript. It is a pure consumer of the canonical Rails API (ADR-0013) and holds no money data of its own. Server state is managed with TanStack Query; the HTTP layer is `openapi-fetch`, typed directly from `docs/api/generated/types.ts` — the TypeScript types generated from the hand-maintained OpenAPI contract (ADR-0017). Routing is client-side (react-router). The build output is static assets served from any static host; there is no SSR server.

## Considered options

- **Vite + React + TS + TanStack Query + openapi-fetch (chosen).** A static SPA that talks only to the Rails API. `openapi-fetch` consumes the already-generated contract types verbatim, so request/response shapes are checked against the real contract at compile time (ADR-0017's end-to-end typing goal). TanStack Query owns caching, refetch-on-focus, and loading/error state. Matches ADR-0017's "SPA" framing and keeps the deploy a static bundle.
- **Next.js (App Router) + TS.** Rejected as primary: the app is 100% behind authentication and online-only, so SSR/RSC and SEO buy little, while adding a Node server, a rendering model split, and more deploy surface. The thin-client model (ADR-0013) wants the browser to be a dumb API consumer, not a second rendering tier.
- **Hand-written fetch + hand-kept TS types.** Rejected: duplicates the contract by hand and reintroduces the drift ADR-0017 exists to eliminate.

## Consequences

- `webapp/` versions independently of iOS (ADR-0016); CI uses a path filter so the web lane runs only on `webapp/**` (and `docs/api/**`, since the client depends on the generated types).
- The web client performs **no money arithmetic**: it formats integer minor units for display and parses input back to integer minor units; every derived figure (fee, remaining, net worth, shortfall) comes from the API. This preserves parity with the Ruby engine (ADR-0015) and follows the thin-client boundary (ADR-0013).
- The contract is the integration boundary: a breaking API change surfaces as a TypeScript error after regenerating `docs/api/generated/types.ts`, and the backend's CI conformance test (ADR-0017) guards the other direction.
- No offline write support; the app requires the network (ADR-0013). A read cache is TanStack Query's in-memory cache only — not a store of record.
