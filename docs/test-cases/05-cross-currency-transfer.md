# 05 — Cross-currency transfer

**Flow:** The owner transfers money across currencies (Wise SGD → VPBank VND), entering amount out, amount in, and rate; the app computes the Fee.
**Source:** PRD #16,14; ui-test-scenarios.md S5; ADR-0003 (transfers use the entered rate, not the fetched valuation rate)
**Seed:** Wise SGD, VPBank Accounts.

---

## TC-05-01 — Fee computed; transfer saves *(Happy path — money correctness)*

- **Priority:** High
- **Type:** Positive
- **Automation:** CrossCurrencyTransferUITests.testCrossCurrencyTransferComputesFeeAndSaves — Fee + save; testCrossCurrencyTransferChangesNetWorthByFee — net worth drops by the Fee, survives relaunch (EFFECT-CONTRACT.md)
- **Preconditions:** App seeded; note Wise SGD and VPBank balances.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Calendar + → Transfer | — | Transfer form shown with a single Amount |
| 2 | Set From = Wise SGD, To = VPBank | — | Sources differ in currency ⇒ form reveals Amount out / Amount in / Rate |
| 3 | Enter amount out / in / rate | out 100, in 1,800,000, rate 18,500 | A Fee row appears = **out × rate − in = 50,000₫** |
| 4 | Tap Save | — | Wise SGD − 100 SGD; VPBank + 1,800,000₫; saved transfer carries the Fee; returns to Add hub |

- **Postconditions:** One cross-currency Transfer persisted.

---

## TC-05-02 — Save disabled until all three numbers present *(Negative)*

- **Priority:** High
- **Type:** Negative
- **Automation:** CrossCurrencyTransferUITests.testCrossCurrencyTransferComputesFeeAndSaves
- **Preconditions:** Transfer form open with From/To of differing currencies (Amount out / in / Rate shown).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter only amount out | out 100 | Save disabled |
| 2 | Add amount in, omit rate | out 100, in 1,800,000 | Save disabled |
| 3 | Add rate | rate 18,500 | Save enabled |

- **Postconditions:** Nothing saved.

---

## TC-05-03 — Transfer is not counted as spending *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Note net worth N and all Envelope remainings.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save a cross-currency transfer | out 100, in 1,800,000, rate 18,500 | No Envelope remaining changes (transfer ≠ Expense) |
| 2 | Read net worth | — | Changes only by the **Fee** (50,000₫), not by the full transferred amount |

- **Postconditions:** One Transfer persisted.

---

## TC-05-04 — Transfer uses entered rate, not fetched valuation rate *(Edge)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Fetched SGD→VND valuation rate differs from the entered 18,500.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Save transfer with rate 18,500 while fetched rate is e.g. 19,000 | — | VPBank credited with the entered amount-in (1,800,000₫) and Fee from 18,500 — the fetched rate is ignored for the transfer (ADR-0003) |

- **Postconditions:** One Transfer persisted.

---

## TC-05-05 — Negative or zero Fee handled *(Edge)*

- **Priority:** Low
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Transfer form, From = Wise SGD, To = VPBank (differing currencies ⇒ cross-currency fields shown).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Enter amount-in ≥ out × rate | out 100, in 1,900,000, rate 18,500 | Fee = out×rate − in = −50,000₫; app shows it without crashing (negative/zero Fee is valid, e.g. a favorable rate) |

- **Postconditions:** One Transfer persisted (or validation message if the app forbids negative Fee — assert whichever the spec intends, no silent wrong number).
