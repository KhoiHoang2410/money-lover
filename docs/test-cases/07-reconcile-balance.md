# 07 — Reconcile a drifted balance

**Flow:** The owner re-enters a source's real balance; the difference is recorded as an Adjustment with a description and an Envelope.
**Source:** PRD #40,41; ui-test-scenarios.md S6; ADR-0006 (ReconcileService)
**Seed:** Cash and other Accounts with computed balances.

---

## TC-07-01 — Higher real balance creates a positive Adjustment *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** ReconcileUITests.testReconcileAdjustsBalanceAndNetWorth — Adjustment moves the Cash row + net worth, survives relaunch (EFFECT-CONTRACT.md); testEnteringRealBalanceEnablesRecord — gating
- **Preconditions:** App seeded; note Cash computed balance C.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add tab → "Update balances" | — | Reconcile screen lists sources with computed balances |
| 2 | Enter real Cash balance | C + 80,000 | Record enabled (a real balance now differs) |
| 3 | Tap Record | — | An **Adjustment** of **+80,000₫** is created carrying a description + Envelope; Cash now equals C + 80,000; screen dismisses |

- **Postconditions:** One Adjustment persisted on Cash.

---

## TC-07-02 — Lower real balance creates a negative Adjustment *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note Cash computed balance C.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter real Cash balance below computed | C − 30,000 | Record enabled |
| 2 | Tap Record | — | Adjustment of **−30,000₫** created; Cash = C − 30,000 |

- **Postconditions:** One Adjustment persisted.

---

## TC-07-03 — Equal balance creates no Adjustment, Record disabled *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Reconcile screen open; Cash computed C.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter real balance equal to computed | C | Record stays **disabled** (no diff) |
| 2 | Leave all sources unchanged, attempt Record | — | No Adjustment created; balances unchanged |

- **Postconditions:** Nothing persisted.

---

## TC-07-04 — Reconcile multiple sources at once *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Reconcile screen; note Cash C and MBBank M.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Change two real balances | Cash = C+10,000, MBBank = M−5,000 | Record enabled |
| 2 | Tap Record | — | **Two** Adjustments created (one per changed source); unchanged sources get none |

- **Postconditions:** Two Adjustments persisted.

---

## TC-07-05 — Adjustment requires/carries an Envelope *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** A reconcile diff exists on Cash.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Record the Adjustment | diff carries Envelope = Reserve (or chosen) | The Adjustment is categorized to an Envelope and shows a description — never an uncategorized silent plug (PRD #41) |

- **Postconditions:** One Adjustment persisted, categorized.
