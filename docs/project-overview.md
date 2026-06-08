# Money Lover — Project Overview

> A one-page narrative for readers, reviewers, and anyone evaluating the project.
> For setup and commands, see the [README](../README.md); for the full rationale
> behind each decision, see the [ADRs](adr/).

---

## What it is

**Money Lover** is a personal finance app for iPhone that tracks net worth across
multiple accounts and currencies, divides income into budget envelopes, manages
long-term savings goals, and surfaces deterministic, rule-based spending advice.

It is **100% on-device**: native SwiftUI, Swift 6.2, SwiftData — no backend, no
accounts, no network sync, and **zero third-party dependencies**. All data lives
locally on the device.

---

## At a glance

| | |
|---|---|
| **Platform** | iOS 26 / Swift 6.2 / SwiftUI only |
| **Persistence** | SwiftData (on-device), isolated behind repositories |
| **Architecture** | MV + pure domain (ADR-0006) |
| **Dependencies** | None — entirely the native stack |
| **Code** | ~8,600 lines of Swift across ~170 files |
| **Domain** | 47 pure `Core` engine/type files |
| **Tests** | 262 unit test cases (Swift Testing, TDD), tiered Smoke/Full UI suites |
| **Decisions** | 12 ADRs |

---

## Architecture

The app is layered so that all the interesting logic is **pure and testable**:

```
SwiftUI Views  →  Stores (@MainActor @Observable)  →  Core engines (pure Swift)
                                │
                                └→  Repositories  ⇄  SwiftData (@Model records)
                                └→  Services       →  live FX / price fetch
```

- **Views** are thin and declarative — they render state and send intent.
- **Stores** are the `@MainActor @Observable` glue: they call pure engines and
  load/save through repositories.
- **Core** holds the domain types and engines as **pure functions over plain
  Swift values** — no SwiftData, no UI, no I/O. This is why the unit suite runs
  in milliseconds without a simulator.
- **Repositories** map domain types ⇄ `@Model` records *at the edge*, keeping the
  persistence layer swappable.

The cornerstone invariant: **money is always an integer count of minor units plus
a currency — never a `Double`.** Floating-point money is designed out at the type
level.

---

## What was hard (and how it was modeled)

These are the decisions that required the most thought — each is an ADR:

- **Goals are funded assets (ADR-0007).** Contributing to a goal is recorded as a
  *Transfer*, not an expense: an account decreases and the goal increases by the
  same amount, so net worth is unchanged — one asset simply becomes another.
- **Holdings derive quantity from trades (ADR-0010).** A holding is created with an
  *opening quantity*, never a money balance. Its live quantity is
  `opening + ΣBuys − ΣSells` — the same balance invariant used for accounts,
  applied to quantity. Selling more than held is blocked.
- **Cross-currency transfers compute the fee.** A transfer records amount-out,
  amount-in, and a *manually entered* transacted rate; the fee is derived as
  `(out × rate) − in`. It deliberately does **not** reuse the auto-fetched market
  rate, because the rate you transacted at differs from the market rate.
- **Backfill restates the opening balance (ADR-0012).** A forgotten past
  transaction is logged as an ordinary transaction *and* offsets its source's
  opening balance, so the current balance stays correct — history is corrected
  without being rewritten.
- **Advice is rule-based; AI only phrases it (ADR-0004).** All spending analysis
  is deterministic Swift ("Signals"); the on-device model is used solely to phrase
  a recommendation, never to compute one.

---

## Engineering practices

- **TDD throughout.** The pure Core engines are written test-first; 262 unit tests
  guard the money math.
- **Tiered tests (ADR-0011).** Every PR runs a curated ≤5-minute **Smoke** gate;
  the **Full** regression runs nightly — fast feedback without sacrificing
  coverage.
- **Generated project.** The Xcode project is generated from `project.yml` via
  XcodeGen, so there are no hand-edited `.pbxproj` merge conflicts.
- **Documented decisions.** Significant choices are ADRs; domain vocabulary is
  pinned in `CONTEXT.md` so the code and the conversation use the same words.
- **Versioning policy (ADR-0008).** SemVer, bumped only when application logic
  changes — docs/test/CI-only PRs ship an identical binary and don't bump.

---

## Status

14 of 16 planned features are implemented and simulator-verified. The two
remaining — **voice entry** (on-device speech + Foundation Models) and the
**accessibility / rotation pass** — require a physical device and are tracked
under `.scratch/money-lover/issues/`.
