# Implementation playbook — for the coding agent

Follow this to implement Money Lover without rework or mistakes. It assumes the design is frozen.

## Before writing any code, read
1. `CONTEXT.md` — the glossary. Use these exact terms in code (types, files, tests): Account, Holding, Card, Liability, Envelope, Allocation, Reserve, Goal, Schedule, Backfill, Reconcile, Adjustment, Transfer, Fee, Signal, Recommendation, Rate.
2. `docs/adr/0001..0006` — the locked decisions and their *why*. Don't relitigate; if a change contradicts an ADR, stop and flag it.
3. `docs/guidelines/engineering.md` and `testing.md` — the how.
4. `.scratch/money-lover/PRD.md` — what to build (user stories, modules).
5. The visual reference: `prototype/index.html` (the "Gradient Rings" look). It is throwaway — copy the *look*, not the code.

## Build order (respect the dependency rule)
Core (pure, TDD) → Persistence (Records + Repository + mapping) → Services (PriceProvider, Speech, ExpenseParser) → Stores → Views. Never write a View before its Store, nor a Store before the Core it needs. Each Core module is test-first.

## Money-correctness invariants (get these wrong = the app lies)
- **Money is integer minor units + currency. Never `Double`/`Float` for money. Ever.**
- `Current balance = Opening balance + Σ balance-affecting Transactions`. Current is always meant to equal reality.
- **Backfill** transactions are informational (`affectsBalance == false`) → they appear in history/reports but do NOT move balances.
- **Reconcile** never silently changes a balance: a diff becomes an **Adjustment** (with description + envelope).
- Credit-card Expense increases that **Liability** at purchase time; it does not touch any Account. Paying the bill is a **Transfer** (Account ↓, Liability ↓), not an Expense.
- Cross-currency **Transfer**: user enters amount-out, amount-in, manual rate; the app **computes the Fee** = out×rate − in. Don't use the auto-fetched valuation rate here.
- Month-end sweep: positive leftover → Reserve; overspend → deduct Reserve; non-Reserve envelopes reset to Allocation; Reserve accumulates.
- **The AI model never does arithmetic.** ExpenseParser extracts text fields; amounts/splits are computed and validated in Swift. Voice entry always passes through the **review screen** — never auto-saves.
- Prices/rates: auto-fetch with cache + stale badge, but **manual override is always available** and is the permanent fallback when the unofficial endpoints break.

## Repeat-offender mistakes — do NOT do these
- ❌ Splitting view bodies with `some View` computed props/methods → extract `View` structs (own files).
- ❌ Content hidden behind the floating dock/FAB → reserve bottom inset (`.safeAreaInset(.bottom)`) on every scrollable docked screen. (Seen in the prototype.)
- ❌ `Double` for money; `String(format:)` or `"₫"+...` for display → use `Money` + FormatStyle `.currency(code: "VND")`.
- ❌ `ObservableObject`/`@Published`/`@StateObject` → use `@Observable` + `@State`/`@Bindable`/`@Environment`.
- ❌ `NavigationView`, `NavigationLink(destination:)`, mixing destination styles → `NavigationStack` + `navigationDestination(for:)`.
- ❌ GCD (`DispatchQueue`), `Task.sleep(nanoseconds:)`, `AnyView`, force-unwrap, `foregroundColor`, fetching bank logos at runtime, `@AppStorage` inside `@Observable`.
- ❌ Engines importing SwiftData or touching `@Model` → engines are pure; map at the Repository edge.
- ❌ Letting the on-device model decide *whether* spending is too high → SignalEngine (rules) decides; model only phrases.

## Definition of Done (per change)
Zero-warning build · tests added & green for any Core logic · no deprecated API · design tokens used (no magic numbers/colors) · bottom inset reserved · FormatStyle for all money/date/number · Dynamic Type + VoiceOver + Reduce-Motion verified · no force-unwrap · one type per file · `#Preview` present · glossary vocabulary used · invariants above upheld.

## Test decisions on every PR (don't skip)
For each PR, explicitly answer — and do — the following (rules: `docs/guidelines/testing.md` § Test tiers):
- [ ] **Changed Core/domain logic?** → add or adjust a **unit** `@Test`. (Default — covers most changes; runs on every PR.)
- [ ] **New/changed user-facing flow a unit test can't reach** (multi-screen, cross-tab freshness, relaunch persistence, navigation)? → add an **XCUITest**.
- [ ] **Chose the new UI test's tier**: **Full-only by default**; promote to **Smoke** only if it's a *core money flow, single-launch, fast (≲30 s), and the smoke suite stays < 5 min*. Smoke promotion = add its `Suite/test()` id to `Smoke.xctestplan`.
- [ ] **Merge gate is green**: `build`, `unit-tests`, `ui-smoke` must pass — these block the merge button (ADR-0011). The nightly `ui-full` does *not* gate PRs.
- [ ] **Bump the version only if the PR changed application logic** (shipping `MoneyLover/` code or build-altering `project.yml`). Test-only changes (new tests, test refactors), CI, config, and docs ship an identical binary → **no bump** (ADR-0008).

## Helper skills to invoke
- `/tdd` — every Core module, test-first.
- `swiftui-pro` — review SwiftUI before merging a feature.
- `swift-concurrency-expert` — if any concurrency warning/data-race appears.
- `swiftdata` (SwiftData Pro) — for the Persistence layer.
- `swiftui-liquid-glass` — if/when adopting Liquid Glass surfaces (optional, matches iOS 26 look).
- `ios-simulator-skill` — build/run/screenshot to verify on simulator.
