# 21 — Holdings & Invest (Buy/Sell)

**Flow:** The owner adds a Holding (gold or stock) by **quantity only** on a dedicated Holdings screen — never a money amount — and Buys/Sells units of it from a VND Account via the **Invest** transaction type. A Holding's live quantity = opening quantity + Σ Buys − Σ Sells, and its value is live quantity × Rate (ADR-0010).
**Source:** Feat 3 & 6; ADR-0010; CONTEXT.md (Holding, Invest).
**Seed:** Holdings `Gold SJC` (5 chỉ) and `FPT` (500 shares); VND Account `VPBank`.

---

## TC-21-01 — Add a gold holding by quantity *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `AddHoldingUITests.testAddGoldHoldingByQuantityPersists`
- **Preconditions:** Config → Holdings open.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap Add holding | — | Form opens with Asset = Gold; there is **no** VND/opening-balance field |
| 2 | Enter quantity | 2 | Quantity accepted in chỉ |
| 3 | Save | — | A new holding row appears; survives a relaunch |

- **Postconditions:** New Holding persisted with opening quantity 2.

---

## TC-21-02 — Add a stock holding via the bundled symbol picker *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Add holding form, Asset = Stock.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Tap Stock | — | Share count + a Stock picker appear; unit is shares |
| 2 | Open the Stock picker and search | "fpt" | Bundled HOSE/HNX list filters to FPT (offline, ADR-0001) |
| 3 | Pick a symbol, enter shares, Save | VNM, 100 | Holding created with that ticker; value comes from the fetched price |

- **Postconditions:** Stock Holding persisted with its ticker.

---

## TC-21-03 — Buy debits the funding account *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `InvestTradeUITests.testBuyDebitsAccountAndPersists`
- **Preconditions:** Add → Add transaction.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Type = Invest, Direction = Buy | — | Account + Holding pickers, Quantity, Unit price, and a live Total appear |
| 2 | Pay from VPBank, buy Gold SJC | 2 chỉ @ ₫7,000,000 | Total cost = ₫14,000,000 |
| 3 | Save | — | VPBank balance drops by ₫14,000,000; Gold SJC live quantity becomes 7 chỉ; survives relaunch |

- **Postconditions:** One `.invest` Buy persisted; account debited, holding quantity raised.

---

## TC-21-04 — Sell credits the account and lowers quantity *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** A Holding with units held.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Type = Invest, Direction = Sell, Gold SJC | 2 chỉ @ ₫9,000,000 | Total proceeds = ₫18,000,000 |
| 2 | Receive into VPBank, Save | — | VPBank rises by ₫18,000,000; Gold SJC live quantity falls by 2 |

- **Postconditions:** One `.invest` Sell persisted; account credited, quantity lowered.

---

## TC-21-05 — Sell cannot exceed units held *(Edge — guard)*

- **Priority:** High
- **Type:** Negative
- **Automation:** `InvestTradeUITests.testSellOverHoldingsDisablesSave` + `testSellWithinHoldingsEnablesSave`
- **Preconditions:** Gold SJC holds 5 chỉ.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Type = Invest, Direction = Sell, Gold SJC, qty 9 | 9 > 5 held | Save is **disabled** |
| 2 | Change qty to 3 | 3 ≤ 5 held | Save becomes enabled |

- **Postconditions:** No negative-quantity Holding can be created.

---

## TC-21-06 — Holding value tracks the live quantity at market *(Edge — valuation)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** `InvestTradeTests.holdingValueTracksLiveQuantityAtMarket` (unit)
- **Preconditions:** Bought below the current market Rate.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Buy 3 chỉ at ₫7M while market is ₫8M/chỉ | — | Holding value = 3 × ₫8,000,000 = ₫24,000,000 (a paper gain), not purchase cost |

- **Postconditions:** None.
