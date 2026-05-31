# 20 — Configuration management

**Flow:** The owner manages setup from Config — sources, envelopes, the Allocation template, the Reserve, goals/schedules, and rate overrides; Advice and Charts live under Config; app supports portrait and landscape.
**Source:** PRD #46,47,48; navigation notes (Advice/Charts under Config)
**Seed:** Full seed (sources, envelopes, template, goals).

---

## TC-20-01 — Config exposes every setup area *(Happy path)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config tab open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read the Config screen | — | Entries for Sources, Envelopes, Allocation template, Reserve, Goals/Schedules, Rate overrides, plus Advice and Charts are all reachable |

- **Postconditions:** None.

---

## TC-20-02 — Edit a goal's schedule *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Goals → Travel.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Edit Travel's schedule | add {month, amount} | Saved; Travel's Expected-by-today and ring % recompute accordingly (cross-ref flow 10) |

- **Postconditions:** Schedule updated.

---

## TC-20-03 — Delete a source in use is handled safely *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A source (e.g. Cash) with existing transactions.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Attempt to delete Cash | — | Either blocked with a clear message, OR deletion handles its transactions consistently (no orphaned txns, no crash, net worth stays coherent) — assert the spec's intended rule |

- **Postconditions:** Per spec.

---

## TC-20-04 — Portrait and landscape both usable *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Any screen open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Rotate the device | portrait → landscape | Layout adapts without clipping or overlap; floating dock/+ still clear of content (PRD #47, layout-safety note) |

- **Postconditions:** None.

---

## TC-20-05 — Editing the Allocation template changes next month's reset target *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Config → Allocation template.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Change Food's template Allocation | A → A + 500,000 | After the next month-end sweep, Food resets to **A + 500,000₫** (template drives the reset target; cross-ref flow 12) |

- **Postconditions:** Template updated.
