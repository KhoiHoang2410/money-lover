# 09 — Calendar

Status: done

## Parent
`.scratch/money-lover/PRD.md`

## What to build
A monthly Calendar tab. Each day cell shows the net (+/−) for that date (spend negative, income positive). A header `‹ MM/YYYY ›` with previous/next, and tapping the label opens a month picker (12-month grid + year ‹ › nav). Tapping a day with activity opens a day detail listing that day's transactions. Amounts respect the censor toggle.

## Acceptance criteria
- [ ] Calendar renders the correct weekday offset and day count for any month/year.
- [ ] Per-day net is computed from transactions; daily-net aggregation unit-tested.
- [ ] Prev/next and month-picker change the displayed month; empty months show a no-data state.
- [ ] Tapping a day opens its transaction list.

## Blocked by
- 02 — Expense & Income
