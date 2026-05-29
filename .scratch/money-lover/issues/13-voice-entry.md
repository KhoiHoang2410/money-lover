# 13 — Voice entry

Status: ready-for-human

## Parent
`.scratch/money-lover/PRD.md`

## What to build
Voice expense capture. A `SpeechTranscriber` wrapper (on-device, Vietnamese) turns speech into text; `ExpenseParser` (an `ExpenseParsing` protocol backed by Apple Foundation Models `@Generable`) extracts amount, currency, note, and a guessed Envelope. The result always lands on a **review screen** for confirmation of source + envelope before saving — never auto-saved. The model does no arithmetic; amounts are validated in Swift. There is no separate people-count field (it stays in the note).

HITL: requires verifying on-device Vietnamese speech recognition and Foundation Models parsing on a real iPhone 15 Pro Max / iOS 26.

## Acceptance criteria
- [x] `ExpenseParser` post-processing unit-tested with a fake model: maps draft → ExpenseDraft, validates amount in Swift, safe empty draft on unparseable input. *(14 tests in `ExpenseParserTests`.)*
- [x] Speech→text uses on-device `SpeechTranscriber` (Vietnamese locale verified at runtime; English fallback). *(Code complete in `LiveSpeechTranscriber`; runtime locale/model verification pending on device.)*
- [x] Voice result populates the review screen; saving requires explicit confirmation. *(`VoiceReviewForm` — Save is a manual toolbar action, never auto-saved.)*
- [ ] Verified on-device that "bánh mì 40k cho 2 người" parses sensibly. **← only remaining step (HITL).**

## Implementation (complete, simulator-buildable)
- Core: `ExpenseDraft`, `RawExpenseExtraction` (pure value types).
- Services: `ExpenseParsing` protocol + `ExpenseParser` (pure `draft(from:)` post-processing); `FoundationModelExpenseParser` (`@Generable ExpenseExtraction`, on-device); `SpeechTranscribing` protocol + `LiveSpeechTranscriber` (iOS 26 `SpeechAnalyzer`/`SpeechTranscriber`, vi-VN→en-US fallback) + `StubSpeechTranscriber` (simulator) chosen by `SpeechTranscriberFactory`.
- Store/Views: `VoiceEntryStore`, `VoiceEntryScreen` (record→parse→review), `VoiceRecordView`, `VoiceReviewForm`. Wired via `InputRoute.voice` (InputHub "Voice expense").
- Info.plist: `NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription` added in `project.yml`.
- Build clean (0 warnings), 104 tests green. The simulator runs the **stub** transcriber (canned "bánh mì 40k cho 2 người") so the parse→review→save flow is exercisable without a mic; the live `SpeechTranscriber` + Foundation Models path runs only on device.

### On-device verification checklist
1. Real iPhone 15 Pro Max, iOS 26, **Apple Intelligence enabled** (Settings → Apple Intelligence & Siri).
2. Build/run to device from Xcode (signing team required — `DEVELOPMENT_TEAM` is empty in `project.yml`; set it in Xcode Signing & Capabilities or via `xcodegen`).
3. Add tab → **Voice expense** → tap mic → grant Microphone + Speech permission → say *"bánh mì bốn mươi nghìn cho hai người"* (or "bánh mì 40k cho 2 người").
4. Expect: review screen with amount ≈ 40,000 VND, note retaining "2 người", an envelope guess (e.g. Food) if one matches. Pick source, confirm, Save.
5. First Vietnamese run may download the on-device speech model (needs network once); subsequent runs are fully offline.

## Blocked by
- 02 — Expense & Income
- 04 — Envelopes & template
