# Money Lover — Bug Reports

Found while building the XCUITest suite (`MoneyLoverUITests/`) against the seeded sample data on
**iPhone 17 Pro simulator, iOS 26, Xcode 26.5**. Severity: P1 blocks a core flow, P2 wrong/confusing
behavior, P3 minor/edge/testability.

| ID | Sev | Area | One-liner | Status |
|----|-----|------|-----------|--------|
| BUG-001 | **P1** | Overview nav | Tapping the empty middle of an Overview row opens nothing (non-hit-testable `Spacer()`) | **Fixed** |
| BUG-002 | P2 | Onboarding | Onboarding can appear over freshly seeded data (stale `@Query` race) | **Fixed** |
| BUG-003 | P3 | Testability | App shipped with **zero** accessibility identifiers | **Fixed** (identifiers added) |
| BUG-004 | P3 | Test determinism | Persisted prefs (censor, onboarding) survive reinstall; no reset path | Mitigated via `UITEST` hook |
| BUG-005 | P3 | Input correctness | Envelope nudge hardcodes `.vnd` regardless of source currency | **Fixed** |
| BUG-006 | P3 | Reconcile input | Real-balance field uses `numbersAndPunctuation` keyboard | **Fixed** |

> All six addressed. The two BUG-001 navigation tests now pass as regression guards (no longer
> `XCTExpectFailure`). Full suite: 11 UI + all unit tests green on iPhone 17 Pro / iOS 26.

---

## BUG-001 — Tapping the middle of an Overview row opens nothing  **(P1, fixed)**
**Area:** `MoneyLover/Features/Overview/OverviewContent.swift`

**Steps to reproduce (before fix):**
1. Launch seeded; open the Overview tab.
2. Tap an account / holding / goal row **on its empty middle** (the gap between the name and the
   trailing amount).

**Expected:** The detail pushes — Account History for a source, Goal detail for a goal.

**Actual (before fix):** Nothing navigates. Tapping directly on the name or the amount *did* work;
tapping the gap did nothing — a confusing, partially-dead tap target.

**Root cause (confirmed by bisection):** The rows are
`NavigationLink(value:) { HStack { icon; VStack{name; subtitle}; Spacer(); AmountText } }` with
`.buttonStyle(.plain)`. With `.plain`, **only the drawn content is hit-testable** — the `Spacer()`
gap is not. XCUITest taps an element's *center*, which lands on the Spacer, so the tap was swallowed.
This is why the seemingly-identical Goals-tab `GoalRing` worked: it has a `.background(...)` filling
its frame (and no Spacer), so the whole tile is hittable.

Bisection that nailed it (throwaway links added to the row, tapped by XCUITest):
- plain `NavigationLink("text", value:)` → **navigates**
- link wrapping bare `AmountText` → **navigates**
- link wrapping `SourceRow` → **fails**
- link wrapping `HStack { Text; Spacer(); Text }` → **fails** ← the Spacer is the culprit

(My first hypothesis — two stacked `navigationDestination(for:)` modifiers — was **wrong**:
collapsing them to a single typed route did not fix it. Recorded here so the next reader doesn't
chase the same dead end.)

**Fix applied:**
- `.contentShape(.rect)` on `SourceRow` / `GoalAssetRow` inside the Overview `NavigationLink`s, so
  the entire row rect (gap included) is hit-testable.
- Also collapsed the Overview stack to a single `OverviewRoute` (`account(UUID)` / `goal(UUID)`) —
  one `navigationDestination` registered once per type, the cleaner shape per the SwiftUI nav
  guidance. (Quality, not the fix.)

**Regression guard:** `OverviewPrivacyUITests.testTapAccountOpensHistory` and
`testTapGoalAssetOpensDetail` now tap the row center and assert the detail opens — both pass.

---

## BUG-002 — Onboarding can show on top of freshly seeded data  **(P2, fixed)**
**Area:** `MoneyLover/App/RootView.swift` (`.task`)

**Cause:** In the first-launch `.task`, the seed runs, then the code checked
`if !didOnboard && sources.isEmpty`. `sources` was the `@Query` array captured at body evaluation —
it does **not** reflect just-seeded inserts within the same task tick, so the check could read empty
and present onboarding over a populated store.

**Fix applied:** Decide onboarding off a **fresh count**, and drop the now-unused `@Query`:
```swift
if !didOnboard {
    let sourceCount = (try? context.fetchCount(FetchDescriptor<SourceRecord>())) ?? 0
    if sourceCount == 0 { showOnboarding = true }
}
```
Removing the unused `@Query` also stops `RootView` re-rendering on every source change.

---

## BUG-003 — App shipped with zero accessibility identifiers  **(P3, fixed here)**
**Area:** whole app

**Finding:** `grep accessibilityIdentifier MoneyLover` returned **0** matches. With no stable
identifiers, every automated or assistive-tech locator must fall back to visible copy (locale- and
layout-fragile) — and several controls (icon-only toolbar buttons, segmented pickers) have no good
text handle at all.

**Action taken:** Added a shared `A11y` identifier namespace (`MoneyLover/App/AccessibilityID.swift`)
and wired identifiers into the screens the suite drives (Overview, Input/Transaction, Reconcile,
Goals, Config). Extend the same pattern as more screens get automated.

---

## BUG-004 — Persisted UI prefs survive reinstall; no reset path  **(P3, mitigated)**
**Finding:** `censorAmounts`, `didOnboard`, `appearance`, `reduceMotion` live in `UserDefaults`,
which the simulator keeps across app reinstalls. The first UI run failed because a previously-toggled
"show amounts" state leaked in, defeating the "censored by default" assertion.

**Mitigation:** The `UITEST` launch hook resets `censorAmounts`/`reduceMotion` and forces
`didOnboard`. Consider a small app-level "reset to defaults" affordance for support/QA.

---

## BUG-005 — Envelope nudge assumes VND regardless of source currency  **(P3, fixed)**
**Area:** `MoneyLover/Features/Input/TransactionForm.swift` (`nudge`)

**Finding:** The live overspend nudge built the prospective amount as
`Money(major: amountMajor, currency: .vnd)` even when the chosen source was a foreign-currency
Account (Wise SGD/USD), comparing an SGD magnitude against a VND envelope allocation.

**Fix applied:** Guard the nudge to VND sources only — the form has no rates to convert, so it no
longer shows a misleading signal for foreign-currency expenses:
```swift
guard kind == .expense, amountMajor > 0,
      let source = selectedSource, source.currency == .vnd, ...
```

---

## BUG-006 — Reconcile real-balance field uses a punctuation keyboard  **(P3, fixed)**
**Area:** `MoneyLover/Features/Reconcile/ReconcileRow.swift`

**Finding:** The real-balance `TextField` used `.keyboardType(.numbersAndPunctuation)` for every
source — awkward for normal numeric entry and inconsistent with the rest of the app.

**Grill note:** a naive switch to `.decimalPad` would **regress** credit cards, which reconcile to
*negative* balances and need a minus key `.decimalPad` lacks.

**Fix applied:** Pick the keyboard by source kind — number pad for the common case, minus-capable
keyboard only where negatives are real:
```swift
.keyboardType(source.kind.isLiability ? .numbersAndPunctuation : .decimalPad)
```

---

### Notes
- During BUG-001 diagnosis one run took ~233s: XCUITest kept retrying a tap that landed on the
  non-hittable `Spacer()` gap. Resolved by the `.contentShape(.rect)` fix; subsequent runs navigate
  in ~9s. (The `.onAppear { store?.load() }` reload was investigated and ruled out as the cause.)
