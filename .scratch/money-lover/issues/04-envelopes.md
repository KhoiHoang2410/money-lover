# 04 — Envelopes & template

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Envelope budgeting. `BudgetEngine` computing remaining per Envelope, applying the Allocation template each month, and tracking the one Envelope marked **Reserve**. Every Expense is assigned to an Envelope, reducing its remaining ("how much left"). A Config·Envelopes screen to define envelopes, set Allocations, save the template, and mark Reserve. Allocations are independent of any single Income.

## Acceptance criteria
- [ ] `BudgetEngine` remaining = allocation − spent; overspend shows negative; unit-tested.
- [ ] Allocation template auto-applies at month start and is editable; unit-tested.
- [ ] Each Expense is assigned an Envelope; envelope remaining updates.
- [ ] Exactly one Envelope can be marked Reserve.
- [ ] Config·Envelopes lists envelopes with allocation, spent, and remaining (overspend in red, with a non-color cue).

## Blocked by
- 02 — Expense & Income
