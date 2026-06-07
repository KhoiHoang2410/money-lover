# Backfill is a normal transaction with an opening-balance restatement

A **Backfill** — recording a *forgotten past* expense or income — is now an **ordinary transaction**. When the owner saves one, two writes commit together: the transaction itself, **and** a restatement of the source's **opening balance** by the opposite amount. The transaction therefore appears on the calendar grid, in account history, and counts toward envelopes, trends, and signals exactly like any other entry — while the account's **current balance is unchanged**, because the money already left (or arrived) before tracking began and the opening balance now reflects that.

This supersedes the original model, where a Backfill was an *informational* transaction carrying `affectsBalance == false`: every balance/calendar/budget engine special-cased that flag to **exclude** the entry. The result was a transaction that was invisible on the calendar and absent from spend math — "not treated as a normal transaction" — which is not what a backfilled entry should be. The flag is removed entirely; there is no longer any concept of a transaction that does not affect balance.

The current-balance neutrality lives in **one creation-time action** (`InputStore.addBackfill`), not on the transaction. Per `current = openingBalance + Σ(signed deltas)`, adding a delta `d` and shifting opening by `−d` leaves current fixed: an expense raises opening by its amount, income lowers it. After that the entry is indistinguishable from a normal one — editing or deleting it later moves the current balance like any other transaction (the opening restatement is a one-time reconciliation, not a linked pair).

The two writes (source update + transaction insert) commit in a **single `ModelContext.save()`** so observing read-models (ADR-0009) reload one consistent state — never the opening restatement without its transaction, or vice-versa.

The Backfill capability is surfaced as a **"Backfilled" toggle** on the Expense/Income add-transaction form (the calendar `+`), with the last choice remembered via `@AppStorage` (the existing `txn.default.*` convention). The previous standalone Backfill screen is removed — one entry point, one code path.

Alternatives rejected:
- **Keep the `affectsBalance` flag** (set it `true` for backfills): leaves a dead field threaded through six engines, persistence, and tests, and a vestigial "informational" concept the domain no longer has.
- **Keep backfills balance-neutral for life** (re-compensate opening on every edit/delete): more consistent in theory, but couples each backfill to a hidden source mutation across its whole lifecycle, complicating the edit/delete paths. The owner asked for "the same as a normal transaction"; a one-time reconciliation at creation matches that.
- **No persisted change, recompute exclusion at read time:** that is the old informational model — the thing this ADR retires.

## Consequences
- `Transaction` and `TransactionRecord` drop `affectsBalance`; `BalanceEngine`, `CalendarMath`, `EnvelopeCapEngine`, `SpendingBucketEngine`, `SignalEngine`, `TrendEngine`, and `HoldingQuantityEngine` drop their exclusion guards and treat every transaction uniformly. A backfilled expense assigned to an envelope now counts toward that envelope's spend (previously a known defect, TC-08-04 — now intended).
- A backfilled entry has **no visual marker** (`TransactionRow` no longer shows "· backfilled"); it reads as a normal transaction.
- The data-backup JSON omits the field; older backups that still carry `affectsBalance` decode fine (the unknown key is ignored). Backup `version` is unchanged.
- `InputStore.addBackfill` is the only place that coordinates the source restatement with the transaction; repositories gain `stageUpdate`/`stageAdd` (mutate without saving) plus `save()` so the pair commits atomically.
