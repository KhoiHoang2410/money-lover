# PRD — Money Lover

Status: ready-for-agent
Type: PRD
Feature: money-lover

## Problem Statement

I have money spread across many places and currencies — VPBank/VIB/MBBank (VND), Wise (SGD, USD), Cash, Gold, and Stock — and I pay mostly by credit card. I can't see, in one number, how much I'm actually worth or how much I owe, and I have no simple way to divide my income into buckets and watch how much is left. I also have several long-term plans (house, car, travel) and no sense of whether I'm ahead of or behind schedule on them. Existing apps are text-heavy, don't fit my multi-currency reality, and can't tell me whether I'm spending too much.

## Solution

A private, on-device iPhone app (just for me) that:

- Shows my **Asset**, **Debt**, and net worth in one VND number, with every Account, Holding, and Credit card broken out.
- Lets me **divide income into Envelopes** (an Allocation template applied monthly) and see how much is left in each, with a **Reserve** envelope that swallows month-end leftovers.
- Tracks **Goals** with a contribution **Schedule** and tells me, per goal, the % I'm ahead of or behind plan.
- Gives **Recommendations** — rule-based signals about overspending and goal pace, surfaced both as an input-time nudge and a summary.
- Makes logging fast: a clean manual **Input** flow plus **voice** ("bánh mì 40k cho 2 người") parsed on-device.
- Lets me correct reality with **Reconcile** (re-enter real balances → Adjustment) and **Backfill** (log a forgotten past transaction without disturbing current balances).

Look-and-feel: the "Gradient Rings" direction — pink/white/yellow, icon-first, minimal text, tasteful motion (ADR-0005).

## User Stories

1. As the owner, I want to enter the Opening balance of each source when I start, so that all later balances are anchored to reality.
2. As the owner, I want to add an Account (bank, Wise, Cash) with its currency, so that I can track money I hold directly.
3. As the owner, I want to add a Holding (Gold in chỉ/lượng, a HOSE stock by ticker and quantity), so that investments count toward my net worth.
4. As the owner, I want to add a Credit card as a Liability, so that what I owe is tracked separately from my Accounts.
5. As the owner, I want a debit card to simply draw from its Account, so that I don't track it as a separate balance.
6. As the owner, I want to see my net worth as one VND number, so that I know my overall position at a glance.
7. As the owner, I want to see total Asset and total Debt separately, so that I understand both sides.
8. As the owner, I want each Account, Holding, and Credit card listed with its value, so that I can see where my money is.
9. As the owner, I want foreign-currency Accounts and Holdings converted to VND on the Overview, so that everything is comparable.
10. As the owner, I want a manual Expense entry (amount, source, envelope, note), so that I can log spending quickly.
11. As the owner, I want a manual Income entry that increases an Account, so that incoming money is recorded.
12. As the owner, I want spending on a credit card to increase that card's debt at purchase time, so that my liability is accurate immediately.
13. As the owner, I want spending on a debit card / Account to reduce that Account, so that balances stay correct.
14. As the owner, I want to record a Transfer between my own places, so that moving money isn't mistaken for spending.
15. As the owner, I want paying a credit-card bill to be a Transfer (Account down, Liability down), so that it isn't double-counted as an expense.
16. As the owner, I want a cross-currency Transfer where I enter amount out, amount in, and the rate, so that the Fee is computed and the real cost is captured.
17. As the owner, I want to define Envelopes and set an Allocation for each, so that I can divide my money into buckets.
18. As the owner, I want to save an Allocation template that auto-applies each month, so that I don't re-budget from scratch.
19. As the owner, I want Allocations to be independent of any single Income, so that I budget over my total available money.
20. As the owner, I want every Expense assigned to an Envelope, so that I can see how much is left in each.
21. As the owner, I want to mark one Envelope as the Reserve, so that leftovers have a home.
22. As the owner, I want month-end leftovers from every Envelope to sweep into the Reserve, so that unspent money accumulates instead of vanishing.
23. As the owner, I want an overspent Envelope to deduct from the Reserve at month-end, so that the overspend is honestly absorbed.
24. As the owner, I want Envelopes to reset to their Allocation each month, so that each month starts fresh.
25. As the owner, I want to create a Goal with a name, target amount, and target date, so that I can plan a big purchase.
26. As the owner, I want a Goal to have a contribution Schedule (specific amounts in specific months, not necessarily flat), so that it matches how I'll actually pay.
27. As the owner, I want to record contributions toward a Goal, so that progress reflects what I've put in.
28. As the owner, I want each Goal to show % ahead of or behind plan vs Expected-by-today, so that I know if I'm on track.
29. As the owner, I want Goals shown as progress rings, so that I can read them at a glance.
30. As the owner, I want rule-based Recommendations about envelope pace and projected overspend, so that I catch problems early.
31. As the owner, I want a Recommendation about a Goal falling behind, so that I can adjust.
32. As the owner, I want an input-time nudge (e.g. "Food 92% spent, 12 days left"), so that I'm warned as I spend.
33. As the owner, I want a Recommendations summary screen, so that I can review everything at once.
34. As the owner, I want recommendation wording to be friendly but the numbers to be exactly right, so that I trust it.
35. As the owner, I want to log an Expense by voice in Vietnamese/English, so that entry is effortless.
36. As the owner, I want the app to transcribe my speech on-device, so that it's private and works offline.
37. As the owner, I want the spoken expense parsed into amount, currency, note, and a guessed Envelope, so that fields are pre-filled (any "for N people" detail just stays in the note).
38. As the owner, I want a review screen before a voice expense is saved, so that I confirm source and envelope and nothing is saved wrong.
39. As the owner, I want amounts validated in the app and the model never doing arithmetic, so that the math is always correct.
40. As the owner, I want a Reconcile mode where I re-enter each source's real balance, so that I can fix drift from forgotten small transactions.
41. As the owner, I want any difference found during Reconcile recorded as an Adjustment with a description and an Envelope, so that the correction is explained and categorized.
42. As the owner, I want a Backfill mode to log a forgotten past transaction flagged informational, so that history is complete without disturbing my current (already-correct) balance.
43. As the owner, I want prices and rates auto-fetched (FX, SJC gold, HOSE stock), so that my net worth isn't stale.
44. As the owner, I want a manual override for any rate or price, so that I'm never blocked when an auto-fetch breaks.
45. As the owner, I want a "stale" indicator and the last-known value when a fetch fails, so that I know the number is old but still see something.
46. As the owner, I want a Configuration screen to manage sources, envelopes, the template, the Reserve, goals/schedules, and rate overrides, so that I control the app's setup.
47. As the owner, I want the app to support portrait and landscape, so that I can use it rotated.
48. As the owner, I want a pink/white/yellow, icon-first interface with minimal text, so that it's pleasant and fast to read.
49. As the owner, I want each Account to show its bank's real logo, so that I recognize sources instantly.
50. As the owner, I want to pick an icon from a list for non-bank sources, envelopes, and goals, so that they're visually distinct.
51. As the owner, I want a monthly Calendar where each day shows my net (+/−) for that date, so that I can see daily activity at a glance, and tap a day to see its transactions.
52. As the owner, I want Charts of total balance over time, spending over time, spending per Envelope over time, and saving per Goal over time, so that I can see trends.
53. As the owner, I want the Quick-add (floating +) to go straight to Expense entry, so that the most common action is one tap away.
54. As the owner, I want all amounts on the Overview hidden by default with an eye toggle to reveal them, so that my balances aren't exposed to shoulder-surfers.
55. As the owner, I want the per-Envelope spending chart to switch between Last 7 days, Last 30 days, and Last 6 months, so that I can see different horizons.
56. As the owner, I want the chart to refuse (with a clear message) when there isn't enough history for the chosen range, so that I'm not shown misleading data.
57. As the owner, I want 30-day and 6-month bars scaled to an average-per-day, so that bars stay visually comparable across ranges.
58. As the owner, I want to save a chart as a screenshot, so that I can keep or share it.
59. As the owner, I want to move the Calendar between months (‹ MM/YYYY ›, and tap the label to pick any month of a year), so that I can review past and future months.

## Implementation Decisions

**Platform & architecture** (ADR-0001, ADR-0002): Native SwiftUI, SwiftData for local storage, 100% on-device, no backend. The only network calls are outbound read-only price/rate fetches (ADR-0003). Requires iOS 26+ on iPhone 15 Pro+ (owner has 15 Pro Max).

**Visual direction** (ADR-0005): "Gradient Rings" — pink→yellow gradient hero, goal progress rings, dense tile/list dashboard, floating dark dock. SF Symbols (+ Phosphor for missing finance glyphs). The browser prototype under `prototype/` is the visual reference and is throwaway.

**Deep modules** (UI-free, tested in isolation; SwiftUI views sit thin on top):

- **Money** — currency-aware amount value type backed by integer minor-units / Decimal (no floating-point drift). Arithmetic, comparison, formatting.
- **BalanceEngine** — `currentBalance(source, transactions) -> Money`. Current balance = Opening balance + Σ of balance-affecting Transactions. Applies Expense/Income/Transfer/Adjustment effects; credit-card Expense increases the card's Liability; ignores Backfill (informational) transactions.
- **BudgetEngine** — Envelope remaining, Allocation template application, month-end sweep. `applyMonthEnd(envelopes) -> envelopes`: positive leftover adds to Reserve, overspend deducts from Reserve, non-Reserve envelopes reset to Allocation.
- **GoalTracker** — `progress(goal, asOf) -> {expected, actual, pct}`. Expected-by-today = cumulative sum of the Schedule due up to `asOf`; pct = actual ÷ expected − 1. Date injected for testability.
- **Valuator** — `toBase(source, rates) -> Money`. Pure conversion of any Account/Holding to base currency VND given a set of Rates. No network.
- **PriceProvider** — protocol; fetches FX (`open.er-api.com`, read `rates.VND`), SJC gold (`edge-api.pnj.io`, `masp=="SJC"`, ×1000/chỉ, ×10 for lượng), HOSE stock (`dchart-api.vndirect.com.vn`, last `c[]`, ×1000). Caches last-known, exposes staleness. Mockable.
- **ReconcileService** — `adjustment(source, realBalance) -> Transaction?`. Produces an Adjustment Transaction for the diff between computed Current balance and the entered real balance; nil if equal.
- **SignalEngine** — `signals(state) -> [Signal]`. Deterministic rules over budget + goal state: envelope pace, projected overspend, goal ahead/behind, Reserve trend, unusually large Expense. The on-device Foundation Models model only phrases a Signal into text; it never does the analysis (ADR-0004).
- **ExpenseParser** — protocol; `parse(text) -> ExpenseDraft` via on-device Foundation Models with `@Generable` guided output (amount, currency, note, guessed envelope). There is no separate people-count field — any "for 2 people" detail stays in the free-text note. The model never does arithmetic; amount/currency are validated in Swift. Speech→text via the Speech framework (`SpeechTranscriber`, Vietnamese on-device). Mockable with a fake model.

**SwiftData entities (shape, not schema):** Source (kind = Account | Liability | Holding; currency; openingBalance; for Holding: quantity + unit + ticker/symbol), Card (kind = debit | credit; → Account for debit, → Liability for credit), Transaction (kind = expense | income | transfer | adjustment; date; amount + currency; source(s); envelope?; note; affectsBalance flag for Backfill; transfer fields: amountIn/out + rate + computed fee), Envelope (name; allocation; isReserve), AllocationTemplate (envelope → planned amount), Goal (name; targetAmount; targetDate; schedule = [{month, amount}]; contributions), Rate (kind = fx | gold | stock; key; value; fetchedAt; isManualOverride).

**Money correctness rules:** Current balance always equals reality; the plug goes to either an Adjustment (Reconcile) or the Backfill informational flag — never silently into a balance. Voice never auto-saves; it routes through a review screen.

## Testing Decisions

A good test asserts **external behavior through a module's public interface**, not internal structure — given inputs, assert the returned Money/Signal/Transaction/progress. No test reaches into private state or SwiftUI view internals.

Unit-tested (Swift Testing), heavily, with table-driven cases incl. edge cases (overspend, zero, negative, cross-currency, month boundaries, schedule gaps):

- **Money** — arithmetic/rounding, no float drift, currency mismatch handling.
- **BalanceEngine** — each Transaction kind's effect; credit-card liability; Backfill ignored; multi-transaction sums.
- **BudgetEngine** — remaining; month-end sweep (positive leftover → Reserve, overspend → Reserve deduction, reset to Allocation); template application.
- **GoalTracker** — Expected-by-today across schedule shapes; % ahead/behind; before-start / after-end dates.
- **Valuator** — conversion across VND/SGD/USD/gold/stock with given Rates.
- **ReconcileService** — diff → Adjustment; equal → nil.
- **SignalEngine** — each rule fires on the right state and stays silent otherwise.

Boundary-tested with fakes (no network, no model):

- **PriceProvider** — parsing/unit conversion against captured sample payloads; cache + stale behavior; fetch-failure → last-known.
- **ExpenseParser** — post-processing (Swift-side split math, currency default) against a fake model returning fixed drafts.

Light XCUITest on the two flows where correctness meets UI: **Input** (manual + voice review → save) and **Reconcile** (enter real balance → Adjustment created). No prior art — this is a greenfield repo, so these tests establish the conventions.

## Out of Scope

- Automatic bank/credit-card transaction capture (impossible on iOS for our case; SePay only sees incoming, not credit-card spend).
- Any backend/server; multi-device sync or iCloud/CloudKit; multi-user.
- Cloud LLM (Claude/Haiku) for recommendations — deliberate future option, not now (ADR-0004).
- Android or web; App Store distribution / monetization (personal use first).
- VIB auto-data (no reliable source); historical FX/price charts.

## Further Notes

- All currency conversion for the Overview uses auto-fetched Rates with manual override; cross-currency **Transfers** always use the manually entered rate + computed Fee, not the fetched valuation rate (ADR-0003).
- Vietnamese on-device parsing (Foundation Models) and the Vietnamese `SpeechTranscriber` locale must be verified on the real device before relying on the voice path — this is why the voice slice is human-in-the-loop.
- Price endpoints (PNJ gold, VNDirect stock) are unofficial and will break eventually; the manual override is the permanent fallback, not an afterthought.
- **Navigation/screens** (from the full prototype): 5 tabs = Overview, Goals, **Calendar**, Input, Config. Advice and Charts live under Config. The Calendar tab shows per-day net; tapping a day lists that day's transactions. Charts = four trend views (total balance, spending, spending per Envelope, saving per Goal).
- **Layout safety (learned from the prototype):** the floating dock and the floating + button overlap scrollable content. Every scrollable screen must reserve bottom inset (safe-area + dock height + FAB clearance) so the last row/button is never hidden behind them. In SwiftUI use `.safeAreaInset(edge: .bottom)` or matching content padding — verify on every screen, this is an easy mistake to repeat.
- **Privacy — censored by default:** Overview amounts are hidden by default (`••••••`) and revealed via an eye toggle; the default state is hidden.
- **Charts:** ranges = Last 7 days / 30 days / 6 months; refuse with a message when history is insufficient; 30d & 6m bars are average-per-day so they're comparable; "Save as screenshot" exports the chart (SwiftUI `ImageRenderer`). Each per-Envelope bar row scales to its own max.
- **Bank logos**: in the real app, bundle bank/brand logos as local assets rather than fetching them at runtime — runtime fetching from a third-party logo service (used in the prototype only) leaks the owner's bank names off-device and contradicts the private/on-device posture (ADR-0001).
- Glossary lives in `CONTEXT.md`; decisions in `docs/adr/0001..0005`. Use that vocabulary in code and issues.
