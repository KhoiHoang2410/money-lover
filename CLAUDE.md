# Money Lover

## Build guidelines (read before implementing)

- **Engineering baseline:** `docs/guidelines/engineering.md` — architecture (MV + pure services, ADR-0006), folder structure, views, data flow, domain⇄SwiftData, navigation, concurrency, performance, Swift style, design tokens, accessibility, assets, Definition of Done.
- **Testing:** `docs/guidelines/testing.md` — Swift Testing + TDD; high→low test cases per Core module.
- **Implementation playbook:** `docs/guidelines/agent-playbook.md` — build order, money-correctness invariants, repeat-offender mistakes, DoD, helper skills.
- **Decisions:** `docs/adr/0001..0006`. **Glossary:** `CONTEXT.md`. **Spec:** `.scratch/money-lover/PRD.md`. **Visual reference:** `prototype/` (throwaway — copy the look, not the code).

Target iOS 26 / Swift 6.2 / SwiftUI only. No third-party frameworks without asking.

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context (`CONTEXT.md` + `docs/adr/` at repo root). See `docs/agents/domain.md`.
