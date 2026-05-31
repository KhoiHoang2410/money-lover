# 12 — Month-end sweep

**Flow:** At month-end, leftovers from every Envelope sweep into the Reserve; overspent Envelopes deduct from the Reserve; non-Reserve Envelopes reset to their Allocation.
**Source:** PRD #22,23,24; ui-test-scenarios.md S9; ADR-0006 (BudgetEngine.applyMonthEnd)
**Seed:** Envelopes Food, Rent, Transport, Fun, Reserve.

---

## TC-12-01 — Positive leftover folds into Reserve *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Food has positive remaining +120,000; note Reserve balance Rv.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Config → Run month-end sweep | — | Reserve = **Rv + 120,000₫** (Food's leftover added) |
| 2 | Read Food | — | Food reset to its Allocation (fresh month) |

- **Postconditions:** Month rolled; Reserve increased.

---

## TC-12-02 — Overspent Envelope deducts from Reserve *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Transport overspent at −40,000; note Reserve Rv.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Run month-end sweep | — | Reserve = **Rv − 40,000₫** (overspend honestly absorbed) |
| 2 | Read Transport | — | Transport reset to its Allocation |

- **Postconditions:** Reserve decreased; Transport reset.

---

## TC-12-03 — Mixed leftovers and overspends net correctly *(Edge)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Food +120,000, Transport −40,000, Fun +10,000; Reserve Rv.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Run month-end sweep | — | Reserve = **Rv + 120,000 − 40,000 + 10,000 = Rv + 90,000₫** |
| 2 | Read all non-Reserve Envelopes | — | Each reset to its Allocation |

- **Postconditions:** Reserve adjusted by the net.

---

## TC-12-04 — Reserve does not reset to an Allocation *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Reserve carries an accumulated balance Rv.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Run month-end sweep | — | Reserve keeps its accumulated balance (after applying leftovers/overspends); it is **not** reset to any Allocation like the others |

- **Postconditions:** Reserve persists across months.

---

## TC-12-05 — Running sweep twice does not double-apply *(Negative)*

- **Priority:** Medium
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A sweep already run for the current month boundary.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Run month-end sweep again for the same boundary | — | No change — Envelopes are not swept twice; Reserve not double-credited/debited |

- **Postconditions:** Idempotent for the same boundary.
