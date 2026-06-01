# 09 — Fund a goal

**Flow:** The owner contributes money to a Goal from an Account; the goal's saved balance rises and the Account drops by the same amount (net worth unchanged).
**Source:** PRD #27; ui-test-scenarios.md S7; ADR-0007 (goals are funded assets)
**Seed:** Goals House, Car, Travel; Accounts MBBank, Savings.

---

## TC-09-01 — Contribute to a goal moves money, net worth unchanged *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** GoalContributionUITests.testContributeToGoal
- **Preconditions:** Note Travel saved balance T, MBBank balance M, net worth N.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Goals tab → tap Travel ring | — | Travel detail pushes |
| 2 | Tap "Add money" | — | Contribution sheet shown |
| 3 | Enter amount + source | 2,000,000, From = MBBank | Form accepts |
| 4 | Tap Save | — | Sheet dismisses to Travel detail; **Travel saved = T + 2,000,000₫**; **MBBank = M − 2,000,000₫** |
| 5 | Read net worth | — | **N unchanged** (goal funding is an asset transfer, ADR-0007) |

- **Postconditions:** One contribution persisted.

---

## TC-09-02 — Contribution raises goal progress % *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Note Travel ring % before.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Contribute to Travel | 2,000,000 from MBBank | Travel ring progress increases consistent with actual ÷ expected (TC references flow 10) |

- **Postconditions:** One contribution persisted.

---

## TC-09-03 — Contribution larger than account balance blocked or allowed-to-negative consistently *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Choose a source with balance B; contribute > B.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Contribute more than the account holds | amount = B + 1,000,000 | Either blocked with a clear message OR the account goes negative consistently and net worth still nets to unchanged — never a goal credited without the account debited |

- **Postconditions:** Per spec decision; assert chosen behavior.

---

## TC-09-04 — Zero contribution rejected *(Negative)*

- **Priority:** Low
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Contribution sheet open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter amount 0, set source | 0, MBBank | Save disabled (no zero contribution) |

- **Postconditions:** Nothing saved.
