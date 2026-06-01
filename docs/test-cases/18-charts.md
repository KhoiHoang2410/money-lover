# 18 — Charts

**Flow:** The owner views trend Charts (total balance, spending, spending per Envelope, saving per Goal), switches per-Envelope ranges (7d / 30d / 6m), is refused when history is insufficient, and saves a chart as a screenshot.
**Source:** PRD #52,55,56,57,58; ui-test-scenarios.md S10 (manual)
**Seed:** Seeded transactions spanning enough history for 7-day range but possibly not 6-month.

---

## TC-18-01 — Four trend charts render *(Happy path)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Charts.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Charts | — | Total balance, spending, spending-per-Envelope, and saving-per-Goal charts all render without crashing |

- **Postconditions:** None.

---

## TC-18-02 — Per-Envelope range switches 7d / 30d / 6m *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Spending-per-Envelope chart open; enough history for all ranges.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Switch to Last 7 days | — | Chart redraws for the 7-day window |
| 2 | Switch to Last 30 days | — | Bars scaled to **average-per-day** so they stay comparable to 7d (PRD #57) |
| 3 | Switch to Last 6 months | — | Bars scaled to average-per-day for the 6-month window |

- **Postconditions:** None.

---

## TC-18-03 — Insufficient history refused with a message *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A range (e.g. 6 months) for which there isn't enough history.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Select Last 6 months with <6 months of data | — | The chart **refuses** with a clear message (PRD #56) — it does NOT draw misleading partial data |

- **Postconditions:** None.

---

## TC-18-04 — Each per-Envelope bar row scales to its own max *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Per-Envelope chart with Envelopes of very different spend.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Compare a low-spend and high-spend Envelope row | — | Each row scales to its own max so a small Envelope's pattern is still readable (PRD notes) |

- **Postconditions:** None.

---

## TC-18-05 — Save chart as screenshot *(Positive)*

- **Priority:** Low
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** A rendered chart.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap "Save as screenshot" | — | An image of the chart is exported (ImageRenderer); the saved image matches what's shown |

- **Postconditions:** One image exported.
