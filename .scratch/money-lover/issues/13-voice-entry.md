# 13 — Voice entry

Status: ready-for-human

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Voice expense capture. A `SpeechTranscriber` wrapper (on-device, Vietnamese) turns speech into text; `ExpenseParser` (an `ExpenseParsing` protocol backed by Apple Foundation Models `@Generable`) extracts amount, currency, note, and a guessed Envelope. The result always lands on a **review screen** for confirmation of source + envelope before saving — never auto-saved. The model does no arithmetic; amounts are validated in Swift. There is no separate people-count field (it stays in the note).

HITL: requires verifying on-device Vietnamese speech recognition and Foundation Models parsing on a real iPhone 15 Pro Max / iOS 26.

## Acceptance criteria
- [ ] `ExpenseParser` post-processing unit-tested with a fake model: maps draft → ExpenseDraft, validates amount in Swift, safe empty draft on unparseable input.
- [ ] Speech→text uses on-device `SpeechTranscriber` (Vietnamese locale verified at runtime; English fallback).
- [ ] Voice result populates the review screen; saving requires explicit confirmation.
- [ ] Verified on-device that "bánh mì 40k cho 2 người" parses sensibly.

## Blocked by
- 02 — Expense & Income
- 04 — Envelopes & template
