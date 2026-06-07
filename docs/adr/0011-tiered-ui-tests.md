# Tiered UI tests: a Smoke gate on PRs, the Full suite nightly

The UI suite grew to 14 XCUITest classes / 31 tests (~20 min on CI) while the unit suite stays ~3 min. Running the whole UI suite on every PR made the merge feedback loop dominated by the slowest, highest-setup tests — the cross-tab + relaunch persistence guards (ADR-0009), cross-currency transfers, rotation, every Config area. Most of those catch *regressions* that don't need to block *every* PR within minutes; they need to be caught *each day*.

So we split the UI suite into two tiers, expressed as two committed **Xcode test plans** wired into the scheme in `project.yml`:

- **`Smoke.xctestplan`** — a curated ~10-test gate that proves the app is fundamentally working: launch, navigate every tab, seed present, and one **single-launch** happy-path write per core flow (expense, reconcile, goal) plus privacy/navigation guards. It runs on every PR (`ci.yml` → `ui-smoke`) next to the full unit suite, with a **≤ 5 min UI-execution budget** (~2.5 min measured) and a `timeout-minutes` backstop against creep.
- **`Full.xctestplan`** — the complete suite (Smoke ⊂ Full). It runs **nightly** (`nightly.yml` → `ui-full`); a failure opens/updates **one sticky GitHub issue** (`needs-triage`, `ci`) listing the failed tests and auto-closes it on the next green run — the same report-to-one-issue pattern as `security-scan.yml`. The slow, high-value regression guards (relaunch persistence, cross-currency, rotation, backfill, freshness) live here.

Unit tests are **not** tiered: the whole unit suite is fast and runs on every PR and nightly.

## How CI reuses one build for both tiers

The compiled test bundles are identical across plans — only the *selection manifest* (`.xctestrun`) differs. The `build` job runs `build-for-testing` for the Full plan (compiles everything, emits `*_Full_*.xctestrun`), then re-runs it for the Smoke plan — an incremental no-recompile step that just writes `*_Smoke_*.xctestrun` alongside. Both manifests are tarred and shared; each test job picks its manifest with `test-without-building -xctestrun *Smoke*` / `*Full*`. One build, two tiers, no duplicate compile.

## Merge gate

Merging into `main` now requires an open PR plus three passing checks — `build`, `unit-tests`, `ui-smoke` — with the branch up to date. The nightly `ui-full` job never runs on PRs, so it is intentionally **not** a required check (a required check that never reports would wedge every PR). The gate lives in `.github/rulesets/main.json` and is applied with `scripts/setup-branch-protection.sh` (`gh api`), since branch protection is a repo setting a workflow can't commit.

## Choosing a tier (the rule the agent follows)

New UI tests are **Full-only by default**. A test is promoted to Smoke only if it exercises a core money flow not already smoke-covered, is single-launch (no `relaunchPreservingData()`), runs fast (≲30 s), and keeps the smoke suite under 5 min. Full procedure: `docs/guidelines/testing.md` § Test tiers.

## Alternatives rejected

- **`-only-testing` lists in the workflow YAML** instead of test plans: the smoke set would live in CI config, drift from the code, and be unusable locally. Test plans are version-controlled, run in Xcode (⌘U → plan), and are edited in one line. Rejected.
- **Swift Testing `@Tag`-based filtering**: UI tests are XCUITest (XCTest), which has no tag traits. Not available.
- **Per-PR risk-based selection** (run only tests for changed paths): a path→test map is complex and drifts; the always-on smoke core gives most of the benefit for far less machinery. Rejected for now.
- **One issue per failing nightly run / per failing test**: produces issue spam or bookkeeping. A single sticky issue, reopened on failure and auto-closed on green, matches the existing security-scan behavior. Rejected.

## Consequences

- PR feedback is bounded: full unit (~3 min) ∥ smoke UI (~2.5 min) after one build, instead of a ~20 min UI tail.
- A regression only the Full suite catches can merge during the day and surfaces as the nightly sticky issue the next morning — an accepted trade for fast PRs. Promote such a test (or its cheaper proxy) into Smoke if it must gate PRs.
- The smoke budget is a maintained constraint: adding to `Smoke.xctestplan` means checking the 5-min budget and the `timeout-minutes` backstop, and considering dropping an older smoke test to Full-only.
- Branch protection must be applied once via the script (and re-applied after editing the ruleset JSON); it is not automatic on clone.

## Amendment (2026-06-07): skip build + tests when no app/test code changed

`ci.yml` now opens with a cheap `changes` job (Ubuntu, ~git diff) that decides whether the push/PR touches anything that ships in or builds the app: the `MoneyLover/`, `MoneyLoverTests/`, `MoneyLoverUITests/` folders, or `project.yml` (the XcodeGen build definition). If none changed — a docs-only, `.claude/skills/`, repo-config, or CI-only PR — `build`, `unit-tests`, and `ui-smoke` are gated off with `if: needs.changes.outputs.code == 'true'` and don't burn macOS runner minutes. (Editing `ci.yml` itself does not trigger a run; a workflow change is validated when it next lands alongside real code.) This is the CI analogue of ADR-0008's "no app logic → no version bump": an identical binary needn't be rebuilt or retested.

This is **not** the per-PR risk-based *test selection* rejected above (a path→test map that drifts). It's a coarse, binary "did any buildable code change at all" gate — all-or-nothing, no mapping to maintain.

The gate is expressed at the **job** level, not via `on: paths-ignore`, on purpose: `build`/`unit-tests`/`ui-smoke` are *required* checks, and a path-filtered workflow that never runs would leave them perpetually "Expected" and wedge the PR. A job skipped by an `if:` condition instead reports a `skipped` conclusion, which GitHub counts as a pass for required checks — so the merge gate stays satisfied while the work is skipped. The ruleset in `.github/rulesets/main.json` is unchanged. `nightly.yml` is schedule-driven and unaffected.
