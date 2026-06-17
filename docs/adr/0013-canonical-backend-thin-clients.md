# Canonical backend, clients are API consumers

A Rails + PostgreSQL backend becomes the single source of truth for all money data; the iOS app and a new web app are API consumers rather than independent stores. This reverses the original on-device-only design (ADR-0001) to enable a web client, multi-device access, and multi-tenant accounts — accepting the loss of full offline operation and on-device-only privacy in exchange.

## Considered options

- **Backend canonical, iOS becomes a thin client (chosen).** Postgres owns the ledger; all money math moves to Ruby. iOS keeps a *read-only* offline cache (balances viewable offline; writes require network) and demotes SwiftData from store-of-record to a display cache. Web is online-only.
- **Backend canonical, clients sync (offline read+write).** Rejected for now: re-introduces a client-side money engine and conflict resolution — contradicts the thin-client goal.
- **iOS stays local-first, backend is opt-in sync/backup.** Rejected: keeps two sources of truth and conflict resolution, and leaves the web app second-class.

## Consequences

- The pure Swift `Core` money engine retires on-device; its logic is re-implemented in Ruby (see ADR-0015).
- iOS requires network to record or edit transactions; offline is view-only of the last cached server response.
- Market-data fetching moves server-side (Sidekiq), superseding the client-fetch posture of ADR-0003; rate overrides become per-user.
- The on-device AI posture of ADR-0002/0004 is paused: Signals are computed server-side in Ruby and returned as plain text; voice entry and LLM phrasing are out of scope for now.
- Build sequence: backend first (golden-tested) → web app → iOS rewrite last. The existing iOS app keeps running on SwiftData until its rewrite.
