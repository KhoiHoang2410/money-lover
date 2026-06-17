# Multi-tenant auth: User/Identity, JWT access + refresh

The backend is multi-tenant from day one: every Account, Holding, Envelope, Goal, Transaction, and rate override is scoped to a `User`, and every endpoint authorizes row ownership. Authentication is modeled as `User` has-many `Identity` — a (provider, external id) pair, with `password` (digest) as the first provider and `google` slotting in later as a new identity row, no schema change. Clients authenticate with a short-lived JWT access token plus a rotating refresh token, stored in an httpOnly cookie on web and the Keychain on iOS.

## Considered options

- **Multi-tenant now, JWT access + rotating refresh (chosen).** Real product shape; painful to retrofit tenancy later. Uniform Bearer auth across native + SPA; refresh rotation supports logout/revocation and pairs cleanly with future OAuth.
- **Single-user, multi-tenant-ready schema.** Rejected: we want registration to be live, not deferred.
- **Opaque server-side session tokens / Rails cookie sessions.** Rejected as the primary mechanism: cookie sessions are awkward for the native iOS client and future third-party clients; opaque DB tokens were a viable alternative but JWT was preferred for stateless verification and OAuth fit.

## Consequences

- `user_id` (or equivalent scope) on every domain table; authorization tested per endpoint, not just authentication.
- `User` carries a **timezone** that defines month boundaries and "today" for resets and Signals.
- Rates are global but **overrides are per-user**; one user's override never affects another.
- Refresh-token rotation and revocation must be implemented and tested; access-token lifetime kept short.
