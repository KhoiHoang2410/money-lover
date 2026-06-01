# 01 — Overview net worth and privacy

**Flow:** The owner reads net worth (one VND number, Asset vs Debt) with amounts hidden by default.
**Source:** PRD #6,7,8,9,54; ui-test-scenarios.md S2; ADR-0001, ADR-0006 (Valuator)
**Seed:** Accounts MBBank, VPBank, VIB, Wise SGD, Wise USD, Cash, Savings; Holdings Gold SJC (5 chỉ), FPT (500); Credit cards VPBank Credit, MBBank Credit.

---

## TC-01-01 — Amounts censored by default *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** OverviewPrivacyUITests.testAmountsCensoredByDefault
- **Preconditions:** App freshly launched; Overview opened for the first time.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Overview | — | Net-worth hero shows `••••••`, not a number |
| 2 | Inspect with VoiceOver | — | The hero reads "hidden", not the figure |

- **Postconditions:** Privacy state remains hidden.

---

## TC-01-02 — Eye toggle reveals then re-hides *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** OverviewPrivacyUITests.testToggleRevealsAmounts
- **Preconditions:** Overview open, amounts hidden (default).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap the eye (Show amounts) toggle | — | Hero reveals a real VND figure; every per-source amount also reveals |
| 2 | Tap the eye toggle again | — | All amounts re-censor to `••••••` |

- **Postconditions:** None.

---

## TC-01-03 — Net worth = Asset − Debt, base currency VND *(Positive — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Overview open; tap eye to reveal.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read total Asset and total Debt | — | Both shown as separate VND figures (PRD #7) |
| 2 | Read net-worth hero | — | Hero == Asset − Debt exactly (no rounding drift); all in VND |
| 3 | Read each Credit card row | — | Each credit card contributes to **Debt**, not Asset |

- **Postconditions:** None.

---

## TC-01-04 — Foreign-currency sources converted to VND *(Edge — valuation)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Overview revealed; Wise SGD, Wise USD, Gold SJC, FPT present.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Read Wise SGD row | SGD balance × FX rate | Displayed in VND (converted), not raw SGD |
| 2 | Read Gold SJC row | 5 chỉ × SJC price | VND value = qty(chỉ) × per-chỉ price; lượng uses ×10 |
| 3 | Read FPT row | 500 × HOSE price | VND value = qty × price |
| 4 | Sum the per-source VND values | — | Equals the Asset total (every source counted once, in VND) |

- **Postconditions:** None.

---

## TC-01-05 — Missing Rate does not crash; shows stale/last-known *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Overview with a foreign source whose Rate failed to fetch (no cached value forced).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Overview with FX/gold/stock fetch unavailable | — | App does not crash; foreign rows show last-known value with a **stale** indicator (PRD #45) |
| 2 | Read net-worth hero | — | Still renders a number; never blank/NaN |

- **Postconditions:** None.
