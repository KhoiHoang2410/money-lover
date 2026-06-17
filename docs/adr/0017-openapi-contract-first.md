# OpenAPI YAML is the hand-maintained contract

A committed OpenAPI YAML document is the hand-maintained source of truth for the JSON API. The web client's TypeScript types are generated from it (so "strict TypeScript" reflects the real contract rather than hand-kept duplicates), and a CI contract test asserts the live Rails responses conform to the YAML, catching drift in either direction.

## Considered options

- **Hand-maintained YAML as contract + TS codegen + CI conformance (chosen).** Enables contract-first parallel work (web can build against the spec while the backend is implemented), strict end-to-end typing, and automated drift detection.
- **Generate YAML from Rails (rswag/request specs).** Rejected as primary: the YAML becomes an output of code, not a shared agreement, weakening contract-first work and making the spec follow implementation rather than lead it.
- **Hand-write YAML as docs only + hand-write TS types.** Rejected: weakest guarantee for a money API; drift is policed manually.

## Consequences

- The API is JSON-only, uses CRUD conventions with non-CRUD actions modeled as createable resources (`POST /reconciliations`, `POST /goals/:id/contributions`, …), roar-rails representers for responses, and dry-validation for params.
- A CI job fails when Rails responses or accepted params diverge from the YAML; TS types are regenerated from the YAML, not edited by hand.
