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

## TC-16-02 — Holdings are added on their own screen, not here *(Positive — valuation)*

- **Priority:** High
- **Type:** Positive
- **Automation:** see flow 21 (`AddHoldingUITests`)
- **Preconditions:** Config → Sources.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Add source | — | The Type picker offers **Account** and **Credit card** only — Holdings live under Config → **Holdings (gold & stock)** now (ADR-0010) |
| 2 | Add gold / stock | see flow 21 | Done on the dedicated Holdings screen, by quantity only (no VND opening balance) |

- **Postconditions:** Sources screen lists Accounts and Cards only.

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
