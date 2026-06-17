# Monorepo with one shared glossary and ADR set

The three codebases live in a single repository — `backend/`, `ios/`, `webapp/` — with the shared `CONTEXT.md` glossary and the cross-cutting `docs/adr/` kept at the root. The ubiquitous language is one domain shared by all three deliveries, so there is one source of domain truth rather than per-app glossaries; the existing `MoneyLover/` app moves under `ios/`.

## Considered options

- **Monorepo, shared root glossary/ADRs (chosen).** Single source of domain truth; coordinated changes (e.g. a contract change touching backend + web + iOS) land in one commit; golden test vectors are trivially shared.
- **Monorepo with per-app CONTEXT.md + CONTEXT-MAP.md.** Rejected: implies separate bounded contexts that diverge in language, which these apps should not.
- **Three separate repos.** Rejected: splits the glossary/ADRs and complicates shared fixtures and coordinated changes.

## Consequences

- App-specific build config and docs live in each app folder; CI uses path filters so each app's pipeline runs only on relevant changes.
- ADR-0008's versioning rule stays scoped to iOS (`MARKETING_VERSION`/`CURRENT_PROJECT_VERSION`); backend and web version independently.
