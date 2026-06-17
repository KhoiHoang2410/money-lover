# 06 — TokenService & auth endpoints

Status: ready-for-agent
Depends on: 02, 05
References: PRD, ADR-0014, ADR-0017

## Goal

Issue and verify tokens, and expose register/login/refresh/logout so clients can authenticate.

## Scope

- **TokenService** (deep, isolation-testable): issue short-lived JWT **access** token; issue long-lived **refresh** token with **rotation** (using a refresh ⇒ old refresh revoked, new pair issued); verify access tokens; revoke on logout.
- Refresh-token persistence/revocation store.
- Endpoints (extend OpenAPI YAML + conformance):
  - `POST /auth/register` (password identity)
  - `POST /auth/login` → access + refresh
  - `POST /auth/refresh` → rotates refresh, returns new access
  - `POST /auth/logout` → revokes refresh
- Storage guidance documented for clients: refresh in httpOnly cookie (web) / Keychain (iOS); access in memory.

## Acceptance criteria

- Access token verifies and expires; an expired access token is rejected 401.
- Refresh rotation invalidates the prior refresh token; reusing a rotated/revoked refresh fails.
- Logout revokes the refresh token.
- All four endpoints conform to the OpenAPI YAML.

## Tests

- TokenService unit: issue/verify, expiry, rotation, revoke, reuse-after-rotation rejected.
- Request specs: register→login→refresh→logout happy path; invalid credentials 401; reused refresh rejected.
