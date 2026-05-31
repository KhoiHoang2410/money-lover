# 13 — Recommendations / signals

**Flow:** The owner receives rule-based Recommendations (envelope pace, projected overspend, goal behind, large expense), as an input-time nudge and a summary screen; wording friendly, numbers exact.
**Source:** PRD #30,31,32,33,34; ADR-0004 (rule-based, model only phrases); ADR-0006 (SignalEngine)
**Seed:** Envelopes with partial spend; Goals House/Car/Travel.

---

## TC-13-01 — Envelope pace warning fires when spend outpaces month elapsed *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Food spent fraction > fraction of month elapsed (e.g. 92% spent, 12 days left).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Recommendations summary | — | A Food pace warning is listed with exact numbers ("Food 92% spent, 12 days left") |
| 2 | Start an Expense to Food | — | Input-time nudge surfaces the same warning (PRD #32) |

- **Postconditions:** None.

---

## TC-13-02 — Quiet state shows no signals *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** All Envelopes under pace; goals on/ahead of plan; no unusual expense.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Recommendations summary | — | No false warnings — empty/"all good" state (signals stay silent when state is calm) |

- **Postconditions:** None.

---

## TC-13-03 — Goal-behind signal fires *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** A goal whose actual < Expected-by-today (behind).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Recommendations | — | A "goal behind plan" signal names the goal and the exact % behind |

- **Postconditions:** None.

---

## TC-13-04 — Numbers are exact; model only phrases *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A known pace warning with computable numbers.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Compare the displayed % / amounts against the engine math | — | Every number matches SignalEngine output exactly; the phrasing is friendly but the figures are never altered by the model (ADR-0004) |

- **Postconditions:** None.

---

## TC-13-05 — Projected-overspend signal *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** An Envelope whose run-rate projects to exceed Allocation by month-end.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Recommendations | — | A projected-overspend signal appears for that Envelope with the projected figure |

- **Postconditions:** None.
