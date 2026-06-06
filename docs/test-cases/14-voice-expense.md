# 14 — Voice expense *(removed)*

**Status:** Removed in 0.5.0 (feat 2). The voice-entry flow, on-device speech transcription, and the
microphone / speech-recognition permissions were taken out of the app. The text expense parser
(`ExpenseParser`) is retained for possible future reuse and still has unit coverage
(`ExpenseParserTests`), but there is no user-facing voice feature to test.

There are no active test cases for this flow.
