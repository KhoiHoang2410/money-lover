# Testing guidelines — Money Lover

Framework: **Swift Testing** (`@Test`, `@Suite`, `#expect`, `#require`, `@Test(arguments:)`), not XCTest. UI: XCUITest, minimal. Build the modules **test-first** (`/tdd` red → green → refactor).

## Principles
- Test **external behavior through the public interface** — given inputs, assert outputs. Never assert private state or SwiftUI view internals.
- The pure Core engines are the priority: deterministic, no SwiftData, no network, **injected `Date`/clock**. Aim for exhaustive case coverage here.
- Test data via **builders/fixtures** (`AccountFixture`, `make(envelope:)`), not ad-hoc literals scattered across tests. Keep amounts in `Money` minor units.
- One behavior per `@Test`; use `@Test(arguments:)` for table-driven cases.

## Test pyramid (what to test, where)
1. **Core engines (unit, exhaustive):** Money, BalanceEngine, BudgetEngine, GoalTracker, Valuator, ReconcileService, SignalEngine. Pure → fast, no setup.
2. **Mapping + Repository (unit, in-memory `ModelContainer`):** Record ⇄ domain round-trips; `affectsBalance` flag respected.
3. **Services with fakes (unit):** `PriceProvider` parsing against captured sample payloads + cache/stale/failure→last-known; `ExpenseParser` post-processing against a **fake** Foundation Models returning fixed drafts.
4. **UI (XCUITest, only where unit can't reach):** Input (manual + voice-review → save) and Reconcile (enter real balance → Adjustment). Nothing else.
- **Do NOT test:** SwiftUI layout, animations, view body output, third-party/system APIs.

## High-level → low-level test cases (write these first)

**Money**
- adds/subtracts same currency; rejects/blocks mixing currencies; never loses precision (minor units); formats via FormatStyle (no float drift on 0.1+0.2-style cases); negative + zero handling.

**BalanceEngine** — `current(opening, txns)`
- Expense on Account reduces it; Income increases it; Expense on credit card increases that Liability (Account untouched); paying card bill (Transfer) lowers Account and Liability; Adjustment moves balance by its diff; **Backfill (informational) txn does NOT change current**; sum of many txns; empty txns → opening.

**BudgetEngine** — remaining + `applyMonthEnd`
- remaining = allocation − spent; overspend → negative remaining; month-end **positive** leftover adds to Reserve; **overspent** envelope deducts from Reserve; non-Reserve envelopes reset to allocation; Reserve does not reset; template application sets allocations; sum of allocations independent of income.

**GoalTracker** — `progress(goal, asOf)`
- Expected-by-today = cumulative Schedule due ≤ asOf (non-flat, with gap months e.g. House Jan–Mar/May/Jul–Sep); % = actual/expected − 1; ahead (+), behind (−); asOf before first scheduled month → expected 0 (no divide-by-zero); asOf after target date; exact-on-plan → 0%.

**Valuator** — `toBase(source, rates)`
- VND Account → identity; SGD/USD Account × FX → VND; Gold Holding (chỉ/lượng, ×10) → VND; HOSE stock qty × price → VND; missing rate → uses last-known/flag, never crashes.

**ReconcileService** — `adjustment(source, realBalance)`
- diff > 0 and < 0 → Adjustment of correct sign + carries description + envelope; equal → nil (no Adjustment).

**SignalEngine** — `signals(state)`
- envelope pace warning fires when spent fraction > month-elapsed fraction (and not otherwise); projected-overspend; goal behind-plan signal; Reserve-shrinking; unusually-large Expense vs history; quiet state → no signals. Numbers are exact (engine, not model).

**PriceProvider (fake/fixtures)**
- parses FX `rates.VND`; SJC gold `masp=="SJC"` ×1000/chỉ (×10 lượng); HOSE last `c[]` ×1000; cache returns last value on fetch failure + marks stale; manual override wins over fetched.

**ExpenseParser (fake model)**
- maps fixed draft → ExpenseDraft (amount, currency, note, guessed envelope); **no people-count field**; amount validated/clamped in Swift (model never does arithmetic); unparseable → safe empty draft for the review screen (never auto-saved).

## TDD loop
For each module: write the failing `@Test` (red) → minimal implementation (green) → refactor with tests green. Don't write a view before its store; don't write a store before the Core it calls. Use the `/tdd` skill.
