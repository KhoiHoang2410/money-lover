# 16 — Setup: add sources

**Flow:** The owner sets up money sources — Account (bank/Wise/Cash with currency), Holding (Gold in chỉ/lượng, HOSE stock by ticker+qty), Credit card as Liability — each with an Opening balance; a debit card simply draws from its Account.
**Source:** PRD #1,2,3,4,5,49,50; CONTEXT.md (Account, Holding, Card, Liability); ADR-0001
**Seed:** Fresh — this flow tests creation, so start from minimal state where possible.

---

## TC-16-01 — Add an Account with currency and opening balance *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Sources.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add Account | name "Wise SGD", currency SGD, opening 1,000 | Saved; appears on Overview with its SGD opening, converted to VND |
| 2 | Read its balance | — | Current balance anchors to the Opening (PRD #1) |

- **Postconditions:** One Account added.

---

## TC-16-02 — Add a Gold Holding in chỉ *(Positive — valuation)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Sources.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add Holding | kind Gold, quantity 5, unit chỉ | Saved; Overview shows VND value = 5 × per-chỉ SJC price |
| 2 | Add Holding in lượng | quantity 1, unit lượng | Value uses the ×10 conversion (1 lượng = 10 chỉ) |

- **Postconditions:** Holdings added.

---

## TC-16-03 — Add a HOSE stock Holding *(Positive)*

- **Priority:** Medium
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Sources.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add Holding | kind Stock, ticker FPT, quantity 500 | Saved; Overview shows VND value = 500 × HOSE price for FPT |

- **Postconditions:** One Holding added.

---

## TC-16-04 — Add a Credit card as a Liability *(Positive — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Config → Sources.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add Credit card | name "VPBank Credit", opening debt 0 | Saved; appears under **Debt** on Overview, not Asset |

- **Postconditions:** One Credit card added.

---

## TC-16-05 — Debit card draws from its Account, not tracked separately *(Negative)*

- **Priority:** Medium
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** An Account exists (e.g. VPBank).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add a debit Card linked to VPBank | — | The debit card does NOT appear as its own balance on Overview |
| 2 | Spend on the debit card | 300,000 | The linked **Account** (VPBank) is reduced; no separate card balance exists (PRD #5,13) |

- **Postconditions:** Debit card linked; spend hits the Account.

---

## TC-16-06 — Bank logo bundled locally, not fetched *(Edge — privacy)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Add a bank Account whose logo is bundled.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Add VPBank with monitoring on network | — | The bank logo renders from a local asset; NO outbound request to a third-party logo service (ADR-0001 privacy posture). Non-bank sources pick an icon from a list (PRD #50) |

- **Postconditions:** One Account added; no logo network call.
