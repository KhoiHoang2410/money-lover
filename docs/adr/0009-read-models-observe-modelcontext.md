# Read-models stay fresh by observing the ModelContext

Stores keep their view state current by **subscribing to `ModelContext` change/save notifications and re-fetching**, instead of loading once on first appearance. A write committed in any tab (e.g. saving an Expense in Add) therefore reflects everywhere it surfaces — the Overview net-worth hero and the source row, the account history, the Calendar day cell and detail, the envelope's remaining — without a tab switch, a manual reload, or an app relaunch.

This replaces the earlier per-screen `.onAppear { store.load() }` pattern, which was the direct cause of the "added a cash expense, nothing updated" bug: each tab owned a `@State` store that called `load()` exactly once and never again, so its snapshot went stale the moment another tab wrote to the context. Scattering a manual reload onto every screen "fixes" each instance but leaves the **class** alive — the next screen someone adds without the incantation silently regresses, and nothing in the type system or the tests forces the incantation to be there.

We keep the store/repository layer from ADR-0006 rather than adopting SwiftUI `@Query` directly in views. `@Query` would make freshness free, but it pulls fetch logic and SwiftData types into the View layer, reversing ADR-0006's dependency rule (`View → Store → Core`, Core touches no SwiftData) and making the read side untestable without a `ModelContainer`. Having the **store** observe the context preserves that boundary: views stay thin, the store still owns view state, and the reload becomes an automatic consequence of a write rather than a thing a human has to remember.

Alternatives rejected:
- **`.onAppear { load() }` per screen (the status quo):** correctness depends on every current and future screen remembering to call it on every path (tab switch *and* in-tab push). Invisible in review, untestable as a guarantee, and already proven to leak (Overview was never patched). This is the pattern this ADR exists to retire.
- **SwiftUI `@Query` in views:** idiomatic and freshness-free, but breaks ADR-0006 — logic and SwiftData leak into Views, the read path can no longer be unit-tested in isolation, and the MV + pure-services boundary erodes one `@Query` at a time.
- **A single app-level shared store** injected into all tabs: removes the per-tab stale-copy problem but concentrates all view state into one object (god-object risk) and *still* needs an explicit refresh trigger on each write — it relocates the bug rather than removing it.

## Consequences
- Stores gain a subscription to `ModelContext` notifications, set up at construction and torn down on deinit; `load()` becomes the re-fetch the notification calls, not a one-shot. The dependency rule of ADR-0006 is unchanged — only the *store* layer learns about persistence change events, never the Core and never the View.
- Cross-tab data **freshness** (in-session propagation) and **persistence** (survival across relaunch) are now distinct, separately-testable guarantees. Both are asserted by the e2e catalog (`docs/test-cases/`) via shared helpers, against this structural contract rather than against the `.onAppear` band-aid — so the tests survive the migration.
- "Freshness" is an implementation/testing concept and deliberately does **not** enter `CONTEXT.md`, which stays a pure domain glossary.
- The transitional `.onAppear { store?.load() }` calls (Input, Calendar, TransactionForm) are removed once the structural subscription lands, so there is one freshness mechanism, not two.
