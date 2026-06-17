# 05 — User, Identity & multi-tenant scoping

Status: ready-for-agent
Depends on: 01
References: PRD, ADR-0014

## Goal

Introduce the auth identity model and the multi-tenant scoping/authorization foundation every domain resource builds on.

## Scope

- `User` (carries `timezone`) and `Identity` (`provider`, `external_id`, `password_digest` for the `password` provider). `User has_many :identities`. Adding a provider later (`google`) = a new identity row, no schema migration.
- Password provider: registration with username + password (digest via bcrypt/argon2), credential verification.
- **Tenant scoping foundation**: a shared mechanism (concern/scope) so every domain model is queried within `current_user` and cross-tenant access is structurally impossible. A base controller exposes `current_user` and forbids access to other users' rows.
- Authorization helper used by all resource controllers (issues 13–20).

## Glossary guard

`Account` is a money source. The auth model is `User` with `Identity`. Do **not** name an auth model `Account`.

## Acceptance criteria

- A user can be created with a `password` identity and authenticated by credentials.
- Any attempt to load another user's row via a scoped finder returns not-found, not the row.
- `User.timezone` persists and is readable for month-boundary/today logic.

## Tests

- Model/unit: identity creation, password verify, provider lookup.
- Authorization request spec: user A cannot read/mutate user B's row on a representative scoped resource (expand per-resource in later issues).
