# 00 — App navigation and seed data

**Flow:** The owner opens the app and reaches every section; seeded sample data is present.
**Source:** ui-test-scenarios.md S1, PRD navigation notes (5 tabs)
**Seed:** Accounts MBBank, VPBank, VIB, Wise SGD, Wise USD, Cash, Savings; Holdings Gold SJC (5 chỉ), FPT (500); Credit cards VPBank Credit, MBBank Credit; Envelopes Food, Rent, Transport, Fun, Reserve; Goals House (~12%), Car (~20%), Travel (~79%).

---

## TC-00-01 — All five tabs are reachable *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** NavigationUITests.testAllTabsReachable
- **Preconditions:** App freshly launched with seed data.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Launch the app | seeded | Overview presents; net-worth hero visible |
| 2 | Tap each tab in turn | Overview, Goals, Calendar, Add, Config | Each screen presents without crash |
| 3 | Return to Overview | — | Overview re-presents; net-worth hero still shown |

- **Postconditions:** None.

---

## TC-00-02 — Seed data is present in each section *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** NavigationUITests.testSeedDataPresent
- **Preconditions:** App freshly launched with seed data.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Overview | — | All 7 Accounts + 2 Holdings + 2 Credit cards listed |
| 2 | Open Goals | — | House, Car, Travel rings shown |
| 3 | Open Config → Envelopes | — | Food, Rent, Transport, Fun, Reserve listed; Reserve flagged |

- **Postconditions:** None.

---

## TC-00-03 — Quick-add (+) opens Expense entry directly *(Edge)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** App launched; any tab.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the floating + button | — | Lands directly on Expense entry (not the Add hub), per PRD #53 |

- **Postconditions:** None.

---

## TC-00-04 — Last row not hidden behind dock/FAB *(Edge — layout safety)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** A scrollable screen with enough rows to scroll (Overview with full seed).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Overview, scroll to the bottom | — | The last row/button is fully visible above the floating dock and + button (bottom safe-area inset reserved) — not clipped |

- **Postconditions:** None.
