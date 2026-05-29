# MV architecture with a pure domain core

The app uses the **MV (Model–View) pattern with pure services**, not MVVM:

- **Views** — thin SwiftUI `View` structs, layout only.
- **Stores** — `@MainActor @Observable` classes holding *view state* and orchestrating calls into the core. No business rules.
- **Core** — pure, `Sendable`, UI-free domain modules (Money, BalanceEngine, BudgetEngine, GoalTracker, Valuator, ReconcileService, SignalEngine, ExpenseParser protocol). All real logic lives here and is unit-tested in isolation.

The domain core operates on **plain value-type structs**, never on SwiftData objects. SwiftData `@Model` classes are a **persistence layer only** (`...Record`), mapped to/from domain types at the edge (a Repository). This keeps every engine testable with zero SwiftData and no `ModelContainer`.

Chosen over MVVM because a per-screen ViewModel layer would duplicate the stores and tempt logic out of the tested core into untested view-models. The mapping cost between `@Model` and domain types is accepted in exchange for a fully pure, fully testable core.

## Consequences
- Dependency rule (one direction): `View → Store → Core`; `Core` depends on nothing UI or SwiftData. Persistence depends on Core (for mapping), not vice-versa.
- Light-first theming (defer dark mode) and locale-aware formatting only (no String Catalog) — see `docs/guidelines/engineering.md`.
- No CloudKit (ADR-0001), so SwiftData `@Attribute(.unique)` and non-optional model properties are permitted.
