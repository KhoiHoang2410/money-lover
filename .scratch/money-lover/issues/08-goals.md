# 08 — Goals

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Goals (house/car/travel) with a per-month contribution **Schedule**. `GoalTracker.progress(goal, asOf)` computes Expected-by-today (cumulative Schedule due ≤ today) and % ahead/behind (actual ÷ expected − 1). Goals screen with progress rings, a Goal detail (schedule chart + contributions list), and an add-goal flow with a per-month schedule editor.

## Acceptance criteria
- [ ] `GoalTracker` unit-tested: non-flat schedule with gap months, ahead/behind, asOf before first month (expected 0, no divide-by-zero), after target date, exact-on-plan.
- [ ] Goals list shows progress rings + % ahead/behind (with non-color cue).
- [ ] Goal detail shows schedule and contributions; contributions can be recorded.
- [ ] Add-goal captures name, target, target date, and a per-month schedule.

## Blocked by
- 02 — Expense & Income
