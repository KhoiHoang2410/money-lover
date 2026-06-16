# MoneyLoverUITests

XCUITest suite driving the owner's everyday flows against the seeded sample data. Best-practice
locators: every element is found by a stable `accessibilityIdentifier` from the shared `A11y`
namespace (`MoneyLover/App/AccessibilityID.swift`), never by visible copy or position.

- **Scenarios** these encode: `docs/testing/ui-test-scenarios.md`
- **Tool rationale** (why XCUITest): `docs/testing/ios-ui-automation-tools.md`
- **Bugs found:** `docs/testing/bug-reports.md`

## Run
```bash
xcodebuild test -scheme MoneyLover \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MoneyLoverUITests
```

## Determinism
Each test launches with `launchEnvironment["UITEST"]="1"`. The `UITEST` hook in `RootView` clears +
reseeds SwiftData, resets persisted UI prefs, and skips onboarding — same known state every run.

## Known-defect tracking
Checks that fail by a documented bug are wrapped in `XCTExpectFailure` with the bug ID (e.g.
BUG-001), so the suite stays green but flips loud the moment the bug is fixed. Remove the wrapper
when closing the bug.
