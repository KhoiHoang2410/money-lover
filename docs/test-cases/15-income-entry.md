# 15 — Income entry

**Flow:** The owner records an Income that increases an Account.
**Source:** PRD #11,19; ADR-0006 (BalanceEngine)
**Seed:** Accounts MBBank, VPBank; Envelopes incl. Reserve.

---

## TC-15-01 — Income increases the target Account *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** IncomeUITests.testIncomePropagatesAcrossTabsAndSurvivesRelaunch — net worth + account rise cross-tab, shows on calendar, survives relaunch (EFFECT-CONTRACT.md)
- **Preconditions:** Note MBBank balance M; net worth N.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Calendar + → Income | amount 10,000,000, To = MBBank | Form accepts |
| 2 | Tap Save | — | MBBank = **M + 10,000,000₫**; net worth = **N + 10,000,000₫** |

- **Postconditions:** One Income persisted.

---

## TC-15-02 — Income does not change any Envelope remaining *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Note all Envelope remainings.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Record an Income | 10,000,000 to MBBank | No Envelope remaining changes — Allocations are independent of Income (PRD #19) |

- **Postconditions:** One Income persisted.

---

## TC-15-03 — Income to a credit card / Holding rejected or routed correctly *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Income form open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Try to set the Income target to a Credit card | To = VPBank Credit | Not offered as an Income target (Income raises an Account, not a Liability) — or the app handles it consistently without inflating Asset wrongly |

- **Postconditions:** Per spec.

---

## TC-15-04 — Zero income rejected *(Negative)*

- **Priority:** Low
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Income form, To = MBBank.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter amount 0 | 0 | Save disabled |

- **Postconditions:** Nothing saved.
