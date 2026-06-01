# 19 — Rates: override and staleness

**Flow:** Prices/rates auto-fetch (FX, SJC gold, HOSE stock); the owner can manually override any rate; a failed fetch shows a stale indicator with the last-known value.
**Source:** PRD #43,44,45; ADR-0003 (external price fetch); ui-test-scenarios.md S12 (manual)
**Seed:** Wise SGD/USD, Gold SJC, FPT requiring Rates.

---

## TC-19-01 — Auto-fetched rates value foreign sources *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Network available; Rates fetch succeeds.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Overview after a fetch | — | Wise SGD/USD, Gold, Stock valued using the freshly fetched Rates; no stale indicator |

- **Postconditions:** Rates cached with fetchedAt.

---

## TC-19-02 — Manual override applies immediately *(Positive — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Rate overrides; note SGD→VND fetched rate.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Override SGD→VND rate | manual = 19,000 | Marked as a manual override |
| 2 | Open Overview | — | Wise SGD revalued at 19,000 (override used, not the fetched value); net worth reflects it |

- **Postconditions:** Override persisted.

---

## TC-19-03 — Failed fetch shows stale + last-known *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A previously cached Rate; force the next fetch to fail.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Trigger a fetch that fails | — | Foreign sources keep their **last-known** value; a **stale** indicator is shown (PRD #45) — never blank, NaN, or a crash |

- **Postconditions:** Last-known retained.

---

## TC-19-04 — Override survives a later successful fetch until cleared *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A manual SGD→VND override set.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Let a successful fetch occur | new fetched SGD rate | The manual override remains in effect (override beats fetch) until the owner clears it |
| 2 | Clear the override | — | Valuation reverts to the fetched rate |

- **Postconditions:** Per action.

---

## TC-19-05 — Gold unit conversion is correct *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** SJC gold price fetched; a Gold Holding in lượng.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Value a 1-lượng Holding | per-chỉ price P | VND value = P × 10 (1 lượng = 10 chỉ); a 5-chỉ Holding = P × 5 — units never mixed up |

- **Postconditions:** None.
