# 22 — Starter envelopes

**Flow:** Instead of creating every Envelope by hand, the owner can seed the list from a single hard-coded **Starter envelopes** set (name + icon, ₫0 allocation). They pick any subset; entries whose name already exists are shown disabled; a select-all / deselect-all toggle helps. If no Reserve exists yet and the designated starter (Savings) is chosen, it becomes the Reserve. Distinct from the recurring *Allocation template* (CONTEXT.md).
**Source:** Feat 4; CONTEXT.md (Starter envelopes, Reserve).
**Seed:** Seeded set includes a `Transport` envelope and a `Reserve`.

---

## TC-22-01 — Seed envelopes from the starter set *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** `StarterEnvelopesUITests.testApplyStarterSetFromEmptyState`
- **Preconditions:** No envelopes yet (empty store).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open Envelopes → Browse starter envelopes | — | The picker lists the starter set |
| 2 | Tap Select all, then Add | — | The chosen envelopes are created with ₫0 allocation and appear in the list |
| 3 | Inspect the Reserve | — | Savings becomes the Reserve (no Reserve existed) |

- **Postconditions:** Envelopes seeded; exactly one Reserve.

---

## TC-22-02 — Existing names are disabled *(Edge — dedupe)*

- **Priority:** High
- **Type:** Edge
- **Automation:** `StarterEnvelopesUITests.testExistingEnvelopeIsDisabledInPicker`
- **Preconditions:** An envelope named "Transport" already exists.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Open the starter picker | — | "Transport" is greyed out / disabled (case-insensitive, trimmed match); others are pickable |
| 2 | Select all | — | Only non-existing entries are selected |

- **Postconditions:** No duplicate envelope is created.

---

## TC-22-03 — Reserve is not stolen when one exists *(Edge — money correctness)*

- **Priority:** Medium
- **Type:** Edge
- **Automation:** `StarterEnvelopesTests.applyKeepsExistingReserveUntouched` (unit)
- **Preconditions:** A Reserve already exists.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Apply the starter set including Savings | — | Savings is added as an ordinary envelope; the pre-existing Reserve is unchanged |

- **Postconditions:** Still exactly one Reserve (the original).
