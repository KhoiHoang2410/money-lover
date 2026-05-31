# 10 — Goal progress tracking

**Flow:** The owner reads each Goal's % ahead of / behind plan vs Expected-by-today, shown as a progress ring.
**Source:** PRD #25,26,28,29; ADR-0006 (GoalTracker), ADR-0007
**Seed:** Goals House (~12%), Car (~20%), Travel (~79%) with contribution Schedules (not necessarily flat).

---

## TC-10-01 — Ring shows % ahead/behind vs Expected-by-today *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** App seeded; open Goals tab.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read each goal ring | House, Car, Travel | Each shows a % equal to actual ÷ Expected-by-today − 1; ahead = positive, behind = negative |
| 2 | Open a goal detail | Travel | Shows actual saved, Expected-by-today, and the % consistently |

- **Postconditions:** None.

---

## TC-10-02 — Expected-by-today honors a non-flat schedule with gap months *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A goal whose Schedule skips months (e.g. House: Jan–Mar, May, Jul–Sep).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Inspect Expected-by-today | asOf = a month inside a gap | Expected = cumulative sum of Schedule entries **due ≤ asOf** — gap month adds nothing, does not interpolate |
| 2 | Compare two asOf dates around the gap | before vs after the gap month | Expected is flat across the gap, then steps up at the next scheduled month |

- **Postconditions:** None.

---

## TC-10-03 — asOf before first scheduled month → no divide-by-zero *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A goal whose first scheduled contribution is in the future.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | View the goal before its schedule starts | asOf < first month | Expected-by-today = 0; the ring shows a sane state (e.g. 0% / "not started"), NOT NaN/∞/crash |

- **Postconditions:** None.

---

## TC-10-04 — Exactly on plan reads 0% *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A goal whose actual == Expected-by-today.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read the % | actual == expected | Shows **0%** (neither ahead nor behind), not a rounding artifact |

- **Postconditions:** None.

---

## TC-10-05 — asOf after target date *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A goal whose target date has passed.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | View the goal past its target date | asOf > targetDate | Expected = full target (whole schedule due); % computed against the complete plan without crashing |

- **Postconditions:** None.
