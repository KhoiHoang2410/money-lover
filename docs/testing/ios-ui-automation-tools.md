# iOS UI Automation — tool survey (the "Playwright for iOS" question)

Playwright drives a web app through the DOM by stable selectors. The iOS equivalents drive a native
app through the **accessibility tree** by stable `accessibilityIdentifier`s. Survey below, then the
choice for this repo and why.

| Tool | Lang | Runs on | Driver | Selector model | Verdict for this repo |
|------|------|---------|--------|----------------|------------------------|
| **XCUITest** | Swift | Sim + device | Apple XCTest/XCTAutomation | `accessibilityIdentifier`, element type | **Chosen.** First-party, zero deps, Swift 6, runs in the existing scheme, CI-friendly. |
| **Maestro** | YAML | Sim + device | Accessibility + idb | text / id / point | Great for fast smoke flows; external binary, less precise assertions, weak on computed-value checks. |
| **Appium (XCUITest driver)** | Any (JS/Py/…) | Sim + device | WebDriver → XCUITest | accessibility id / predicate / class chain | Cross-platform & Playwright-like API, but heavy server, slower, an extra moving part for a solo on-device app. |
| **idb / fb-idb** | CLI/Py | Sim + device | Companion daemon | point / accessibility | Low-level plumbing (tap by point), not a test framework. Useful under Maestro. |
| KIF / EarlGrey 2 | ObjC/Swift | Sim + device | In-process | accessibility | Aging; EarlGrey unmaintained-ish. Skip. |

## Why XCUITest here
- The app is **on-device, single-target, SwiftUI, Swift 6.2, iOS 26** with no backend. A first-party
  in-scheme test target keeps everything in one toolchain (`xcodebuild test`), no servers, no extra
  language runtime — the lowest-friction "Playwright equivalent."
- XCUITest reads the **same accessibility tree** VoiceOver uses, so investing in identifiers improves
  accessibility *and* testability at once.
- It runs the existing unit suite (`MoneyLoverTests`) and the new UI suite (`MoneyLoverUITests`) from
  one command, locally and in CI.

Maestro remains a good optional layer for quick visual smoke flows; this suite deliberately uses
XCUITest for precise, value-level assertions (e.g. "net worth is censored", "Save disabled until
valid").

## Best practices applied in `MoneyLoverUITests/`
1. **Every driven element has a unique, stable `accessibilityIdentifier`** — namespaced
   `screen.element`, defined once in `MoneyLover/App/AccessibilityID.swift` (the `A11y` enum) and
   shared by both the app and the test target. No taps by visible copy, index, or coordinate
   (coordinate taps used only as a diagnostic). Locale- and layout-independent.
2. **Deterministic launch state.** Tests launch with `launchEnvironment["UITEST"]="1"`, which clears
   + reseeds SwiftData and resets persisted UI prefs, then skips onboarding — every test starts from
   the same known seed. (See the `UITEST` hook in `RootView`.)
3. **One scenario per test, asserting external behavior** — navigation happened, a control is
   enabled/disabled, a value is censored — never reaching into view internals (mirrors the unit
   suite's "public-interface only" rule in the PRD).
4. **Right element type for the check.** Enabled/disabled and tap assertions target `buttons[id]`,
   not a generic `.any` match (a wrapper can falsely read as enabled). Reads of displayed values use
   the element's `label`.
5. **Robust text entry.** `typeInField` clears via `delete` keystrokes (numeric Form fields expose no
   "Clear text" affordance).
6. **Known defects are tracked, not hidden.** Failing-by-design checks are wrapped in
   `XCTExpectFailure` referencing the bug ID, so the suite stays green but flips loud the moment the
   bug is fixed.

## Run it
```bash
# Unit + UI
xcodebuild test -scheme MoneyLover \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# UI only
xcodebuild test -scheme MoneyLover \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MoneyLoverUITests
```
