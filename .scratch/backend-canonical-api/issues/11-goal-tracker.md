# 11 — GoalTracker (pure, golden-tested)

Status: ready-for-agent
Depends on: 03, 04
References: PRD, ADR-0015, ADR-0007, CONTEXT.md (Goal, Schedule, Expected-by-today, status, shortfall)

## Goal

Compute goal progress: schedule cumulation, expected-by-today, per-line status, and shortfall.

## Scope

- Pure module over a Goal's Schedule (month → planned amount) and its Contributions:
  - **Expected-by-today** = cumulative scheduled due through current date (user timezone).
  - **% ahead/delay** = actual contributed ÷ expected − 1.
  - Per-line **status**: Funded / Due (current month, still fundable) / Missed (past month unmet) / Pending (future).
  - **Shortfall** per unmet line = scheduled − contributions allocated, where Contributions fill lines **oldest-first**.
- Goal balance = Σ Contributions (used by NetWorth, issue 09).

## Acceptance criteria

- Reproduces goal-tracking golden fixtures byte-identically, including oldest-first shortfall allocation and the four statuses.
- "Today" is evaluated in the user's timezone.

## Tests

- Golden-vector spec across schedules (non-flat, discontinuous).
- Unit: Due vs Missed boundary at month edge; oldest-first fill; ahead/delay percentage.
