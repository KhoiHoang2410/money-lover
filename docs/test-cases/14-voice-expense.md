# 14 — Voice expense

**Flow:** The owner logs an Expense by voice (Vietnamese/English), transcribed on-device, parsed into fields, confirmed on a review screen before saving. Voice never auto-saves.
**Source:** PRD #35,36,37,38,39; ADR-0004 (model phrases, never arithmetic); ADR-0006 (ExpenseParser); ui-test-scenarios.md S8 (manual)
**Seed:** Envelopes Food, Transport, Fun; Cash, MBBank.

---

## TC-14-01 — Spoken expense parsed and routed to review *(Happy path)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate — manual, on-device)
- **Preconditions:** Voice entry available; on-device Speech + Foundation Models ready.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Start voice entry, speak | "bánh mì 40k cho 2 người" | Transcribed on-device (offline) |
| 2 | Parser fills fields | — | amount = 40,000, currency = VND, note contains "cho 2 người", a **guessed** Envelope (e.g. Food) pre-filled |
| 3 | Review screen appears | — | Nothing saved yet; review shows parsed fields for confirmation |

- **Postconditions:** Draft pending, not persisted.

---

## TC-14-02 — Voice never auto-saves *(Negative — money correctness)*

- **Priority:** High
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** A parsed voice draft on the review screen.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Parse a voice expense | "cà phê 45k" | The expense is NOT saved automatically — it waits on the review screen until the owner confirms |
| 2 | Dismiss without confirming | — | No transaction persisted |

- **Postconditions:** Nothing saved.

---

## TC-14-03 — Owner confirms source/envelope before save *(Positive)*

- **Priority:** High
- **Type:** Positive
- **Automation:** none (candidate)
- **Preconditions:** Review screen with a parsed draft (Envelope guessed, source maybe empty).

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Set/confirm source and envelope | From = Cash, Envelope = Food | Required fields satisfied |
| 2 | Confirm save | — | Expense persisted with the confirmed source/envelope; Cash and Food reduced |

- **Postconditions:** One expense persisted.

---

## TC-14-04 — Model does no arithmetic; amount validated in Swift *(Edge — money correctness)*

- **Priority:** High
- **Type:** Edge
- **Automation:** none (candidate)
- **Preconditions:** Speak an utterance implying a split or sum.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Speak | "bánh mì 40k cho 2 người" | Saved amount = **40,000** (the total spoken), NOT 20,000 — the model does not divide; "2 người" stays in the note only |
| 2 | Inspect the amount path | — | Amount/currency validated in Swift; any model-produced arithmetic is ignored (PRD #39) |

- **Postconditions:** Per confirmation.

---

## TC-14-05 — Unparseable speech degrades gracefully *(Negative)*

- **Priority:** Medium
- **Type:** Negative
- **Automation:** none (candidate)
- **Preconditions:** Speak something with no recognizable amount.

| # | Step | Test Data | Expected Result |
|---|------|-----------|-----------------|
| 1 | Speak with no amount | "hôm nay trời đẹp" | Review screen opens with amount empty; Save stays disabled until the owner enters one — no crash, no garbage amount |

- **Postconditions:** Nothing saved.
