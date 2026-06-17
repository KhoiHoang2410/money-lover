# 02 — OpenAPI contract harness, TS codegen & conformance gate

Status: ready-for-agent
Depends on: 01
References: PRD, ADR-0017

## Goal

Establish the hand-maintained OpenAPI YAML as the contract, the TS type generation, and the CI conformance test. Every later resource issue extends the YAML and relies on this gate.

## Scope

- Create the committed **OpenAPI 3.x YAML** at the shared root docs area (e.g. `docs/api/openapi.yaml`). Seed it with shared components: error schema, pagination, money-as-integer-minor-units representation, auth security scheme (bearer).
- Wire **TypeScript type generation** from the YAML into a script (output consumed later by `webapp/`); CI regenerates and fails if checked-in types are stale.
- Wire a **contract conformance test** in the backend test suite: live API responses and accepted params are validated against the YAML. Provide a helper so each resource spec asserts conformance.
- Document in `backend/README` how to extend the YAML when adding an endpoint and how the gate works.

## Acceptance criteria

- The YAML validates against the OpenAPI schema in CI.
- TS types generate deterministically; a drift between YAML and committed types fails CI.
- The conformance helper is usable from request specs; a deliberately wrong response shape fails the conformance assertion (proven with a temporary fixture).

## Tests

- Meta-test: conformance helper flags a known-bad payload (proves the gate bites).
- CI job: `openapi.yaml` lints; TS codegen is up to date.
