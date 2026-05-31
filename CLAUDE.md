# Money Lover

## Build guidelines (read before implementing)

- **Engineering baseline:** `docs/guidelines/engineering.md` — architecture (MV + pure services, ADR-0006), folder structure, views, data flow, domain⇄SwiftData, navigation, concurrency, performance, Swift style, design tokens, accessibility, assets, Definition of Done.
- **Testing:** `docs/guidelines/testing.md` — Swift Testing + TDD; high→low test cases per Core module.
- **Implementation playbook:** `docs/guidelines/agent-playbook.md` — build order, money-correctness invariants, repeat-offender mistakes, DoD, helper skills.
- **Decisions:** `docs/adr/0001..0008`. **Glossary:** `CONTEXT.md`. **Spec:** `.scratch/money-lover/PRD.md`. **Visual reference:** `prototype/` (throwaway — copy the look, not the code).

Target iOS 26 / Swift 6.2 / SwiftUI only. No third-party frameworks without asking.

## Versioning — bump on every PR (ADR-0008)

**Every PR must bump the app version** before it opens. SemVer, pre-1.0 simplified (`https://semver.org/`, spec §4):

1. **MARKETING_VERSION** — any `feat:` commit in the branch → MINOR (`0.2.0`→`0.3.0`); only `fix:`/`chore:`/`docs:`/`refactor:`/`test:` → PATCH (`0.2.0`→`0.2.1`). Breaking change → MINOR too (no MAJOR until the 1.0 release). One bump per PR, by its highest-priority change.
2. **CURRENT_PROJECT_VERSION** — always `+1`, every PR.
3. Edit the values in **`project.yml`** — the only committed source of truth (`MoneyLover.xcodeproj` is gitignored, regenerated via `xcodegen generate`). Don't hand-edit the pbxproj.
4. Add a `CHANGELOG.md` entry under the new version (Keep a Changelog format).

Full procedure: `docs/guidelines/engineering.md` § Versioning & PRs.

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (`CONTEXT.md` + `docs/adr/` at repo root). See `docs/agents/domain.md`.
