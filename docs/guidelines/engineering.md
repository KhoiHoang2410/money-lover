# Engineering guidelines — Money Lover

Authoritative coding baseline. Read with `CONTEXT.md` (glossary) and `docs/adr/*`. Target **iOS 26**, **Swift 6.2**, strict concurrency, SwiftUI only (no UIKit unless asked, no third-party frameworks without approval).

## 1. Architecture (ADR-0006) — MV + pure services
Dependency direction is one-way: **View → Store → Core**. Persistence maps to Core types.

- **View** — `View` structs, layout only. No business logic, no networking, no formatting math.
- **Store** — `@MainActor @Observable final class`, owns view state, calls Core + Repository. No domain rules.
- **Core** — pure `Sendable` structs/enums + stateless engines. UI-free, SwiftData-free, deterministic (inject `Date`/clock). 100% unit-tested.
- **Persistence** — SwiftData `@Model` `…Record` classes + a Repository that maps Record ⇄ domain type. Engines never see `@Model`.

## 2. Folder structure (by feature)
```
MoneyLover/
  App/                 # App entry, root TabView, DI container
  DesignSystem/        # Theme tokens, shared components (RingView, GradientHeader, AmountText…)
  Core/                # pure domain: Money, BalanceEngine, BudgetEngine, GoalTracker,
                       #   Valuator, ReconcileService, SignalEngine, ExpenseParsing (protocol)
  Persistence/         # SwiftData @Model records + Repository + mapping
  Services/            # PriceProvider (network), SpeechTranscriber wrapper, FoundationModels parser
  Features/
    Overview/  Goals/  Calendar/  Charts/  Input/  Reconcile/  Config/   # each: Screen + Store + subviews
  Resources/           # Assets.xcassets (bank logos, colors), Info.plist
MoneyLoverTests/       # mirrors Core/ and Persistence/ and Services/
MoneyLoverUITests/     # Input + Reconcile flows only
```
One type per file. Filename = type name. Flag any file with multiple `struct`/`class`/`enum` definitions.

## 3. Views
- **Never** split a body with `some View` computed properties/methods (even `@ViewBuilder`). Extract a real `View` struct in its own file. Long bodies are a smell.
- Button actions and any logic go in **methods/stores**, not inline in `body`, `task`, `onAppear`.
- `Button("Save", systemImage: "checkmark", action: save)` — pass the action directly; never icon-only without text.
- `#Preview` (not `PreviewProvider`) on every screen + reusable component.
- `TabView(selection:)` bound to an **enum** `Tab` (`Tab("Overview", systemImage: "house", value: .overview)`), never Int/String.
- Empty/missing states use `ContentUnavailableView`. Icon+text side by side uses `Label`, not `HStack`.

## 4. Data flow
- Shared state: `@MainActor @Observable final class` + `@State` (ownership) + `@Bindable`/`@Environment` (passing). **No** `ObservableObject`/`@Published`/`@StateObject`/`@ObservedObject`/`@EnvironmentObject`.
- `@State` is `private`, owned by the creating view.
- No `Binding(get:set:)` in `body` — use `@State`/`@Binding` + `.onChange`.
- Numeric input: `TextField("Amount", value: $amount, format: .number)` + `.keyboardType(.decimalPad)`. Never bind money to a `String`.
- Never `@AppStorage` inside `@Observable`. Never store secrets/PII in `@AppStorage` (use Keychain — not needed here since fully local, no secrets).
- Domain structs conform to `Identifiable`; don't pass `id: \.x` into SwiftUI.

## 5. Domain ⇄ SwiftData
- Money is a dedicated value type: store integer **minor units** + currency. **Never use `Double`/`Float` for money.** No `Decimal` arithmetic in `body`.
- `@Model final class AccountRecord` etc. live in Persistence; Repository maps to/from `Core` structs.
- `Current balance = Opening balance + Σ (balance-affecting Transactions)`. Backfill txns are `affectsBalance == false` → excluded. (CONTEXT.md)
- Use `ModelContext.fetchCount(_:)` for counts when you don't need live updates.
- No CloudKit → `@Attribute(.unique)` and non-optional model properties are allowed.

## 6. Navigation
- `NavigationStack` + `navigationDestination(for:)` (registered once per type). Never `NavigationView` or `NavigationLink(destination:)`. Never mix the two destination styles.
- `sheet(item:)` (not `isPresented`) for optional data; `sheet(item: $x, content: SomeView.init)`.
- `confirmationDialog`/`alert` attached to the triggering control. Single-OK alerts: empty button closure.

## 7. Concurrency (Swift 6.2 strict)
- `async`/`await`, actors, `Task`. **Never** GCD (`DispatchQueue.*`). `Task.sleep(for:)` not `(nanoseconds:)`.
- `@Observable` stores are `@MainActor`. Network/parse work off the main actor; hop back for UI.
- All shared mutable state actor-protected; no data races, satisfy `Sendable`. `Task.detached` only with strong justification.

## 8. Performance
- Toggle styles with **ternaries**, not `if/else` view branching (avoid `_ConditionalContent`).
- Avoid `AnyView` (use `@ViewBuilder`/`Group`/generics). `LazyVStack`/`LazyHStack` for long lists (transaction history, calendar).
- Keep `init` trivial; move work to `task()` (auto-cancelled), not `onAppear`.
- `body` runs often: no sorting/filtering inline — derive with `let` from source of truth, or cache in `@State` only with explicit invalidation.
- No stored `DateFormatter`; use `Text(_, format:)`.

## 9. Swift style
- `foregroundStyle` not `foregroundColor`; `.circle`/`.borderedProminent` static members; `bold()` not `fontWeight(.bold)`.
- Money/number/date display via **FormatStyle**: `Text(amount, format: .currency(code: "VND"))`, `Text(date, format: .dateTime.day().month().year())`. **Never** `String(format:)` or `"₫"+...`.
- No force-unwrap/force-`try` (use `if let`/`guard let`/`??`/`try?`); `fatalError("why")` only for truly unrecoverable. `if let value {` shorthand. Omit `return` in single-expression bodies; use `if`/`switch` as expressions.
- User-text filtering: `localizedStandardContains`. `Double` over `CGFloat`. `count(where:)` over `filter{}.count`. `Date.now` over `Date()`.
- Errors from user actions surface in UI (alert), never swallowed with `print`.

## 10. Design system (light-first)
Put **all** tokens in a `Theme`/`DS` enum — colors, spacing, radii, typography roles, animation timings, and the **bottom safe-inset** for the dock/FAB. No scattered magic numbers; no hard-coded padding/spacing unless asked.
- Palette (light): pink `#FF5C8A` / soft `#FFE3ED` / deep `#E03E70`; yellow `#FFC94D` / soft `#FFF3D6` / deep `#F0A500`; ink `#241A1F`; ok `#2BB673`, warn `#F0A500`, bad `#FF4D4D`. Hero gradient: 160° pink → `#FF8F6B` → yellow. Define as **asset-catalog Color sets** so dark variants can be added later without code change.
- Tap targets ≥ 44×44. No `UIScreen.main.bounds` (use `containerRelativeFrame`/`GeometryReader` only if unavoidable). Avoid fixed frames; allow flex for Dynamic Type + rotation.
- **Bottom inset:** every scrollable docked screen applies `.safeAreaInset(edge: .bottom)` (or matching padding) covering safe area + dock height + FAB clearance, so the last row/button is never hidden. (Regression seen in the prototype.)

## 11. Accessibility
- Dynamic Type everywhere (`.font(.body/.headline/...)`); avoid `.caption2`. Custom sizes via `@ScaledMetric` / `.font(.body.scaled(by:))`. No forced sizes.
- Every icon-only button keeps a text label (VoiceOver). Decorative images `Image(decorative:)` / `accessibilityHidden`.
- Reduce Motion → swap large motion (the floating/ring animations) for opacity.
- `+`/`−` day cells, "stale" badges, ahead/behind colors must also differ by **icon/shape** (respect `accessibilityDifferentiateWithoutColor`), not color alone.
- Tappable = `Button`, never `onTapGesture` (unless tap location/count needed → add `.accessibilityAddTraits(.isButton)`).
- Censored amounts (`••••••`) must still expose a sensible VoiceOver label state ("hidden").

## 12. Assets & networking
- Icons: **SF Symbols** first; Phosphor only for finance glyphs SF lacks. Bank logos: **bundle in Assets.xcassets** — do NOT fetch logos at runtime (privacy; ADR-0001 note).
- `PriceProvider` (Services): `async`/`await` `URLSession`, the three endpoints in ADR-0003, cache last-known, expose `stale`, always allow manual override. No secrets in the repo (none needed — fully local, no API key).

## Definition of Done (every change)
Compiles with **zero warnings** · unit tests added/green for any Core logic · no deprecated API (check `swiftui-pro` references) · tokens used (no magic numbers/colors) · bottom inset reserved · formatting via FormatStyle · Dynamic Type + VoiceOver + Reduce-Motion OK · no force-unwrap · one type per file · `#Preview` present · glossary vocabulary used.
