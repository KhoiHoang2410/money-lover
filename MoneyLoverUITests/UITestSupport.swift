import XCTest

/// Shared launch + interaction helpers for the Money Lover UI suite.
///
/// Conventions (automation best practice):
/// - Every element a test drives is found by its stable `accessibilityIdentifier` (see `A11y`),
///   never by visible copy, position, or index.
/// - The app launches into a clean, seeded store via the `UITEST` env hook, so every test starts
///   from the same known state and onboarding is skipped.
extension XCUIApplication {
    /// Launch with the deterministic seeded store (clear + seed + skip onboarding).
    static func launchSeeded() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST"] = "1"
        app.launch()
        app.waitUntilReady(seeded: true)
        return app
    }

    /// Launch with an empty store (clear + skip onboarding, no seed). Used to prove that a Source
    /// created after a tab's store first loaded becomes visible there without restarting the app.
    static func launchEmpty() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST"] = "1"
        app.launchEnvironment["UITEST_EMPTY"] = "1"
        app.launch()
        app.waitUntilReady(seeded: false)
        return app
    }

    /// Relaunch the SAME app without clearing the store (UITEST_PRESERVE) — proves a write
    /// survived a cold start. The on-disk container persists across the terminate/launch, while the
    /// preserve hook skips the clear+seed a normal UITEST launch would do.
    func relaunchPreservingData() {
        launchEnvironment["UITEST"] = "1"
        launchEnvironment["UITEST_PRESERVE"] = "1"
        terminate()
        launch()
        // Preserve relaunches re-open the on-disk store with no clear/seed, so there's no seed-commit
        // race — gating on the shell is enough; the per-test post-relaunch reads wait on their own rows.
        waitUntilReady(seeded: false)
    }

    /// Block until the app is ready to drive after a launch.
    ///
    /// The `TabView` (and its tab bar) renders immediately, but a `UITEST` launch clears + seeds the
    /// store (~100 transactions) asynchronously *afterwards*. Handing control back at first render lets
    /// the next step — opening the form and picking a seeded "Cash"/"Food", reading a balance — race
    /// that seed and flake as "option did not appear". So for a seeded launch we additionally wait for
    /// a seed marker (the always-seeded Cash source row on the initial Overview) to confirm the seed
    /// committed. An empty/preserve launch has nothing to seed, so the shell wait is enough.
    func waitUntilReady(seeded: Bool) {
        _ = tabBars.firstMatch.waitForExistence(timeout: 20)
        guard seeded else { return }
        _ = element(A11y.Overview.sourceRow("Cash")).waitForExistence(timeout: 20)
    }

    // MARK: - Cross-surface assertion helpers (the Effect Contract — see docs/test-cases/)

    /// Make amounts visible if they are currently censored. Idempotent: reads the net-worth hero's
    /// state first, so calling it when already revealed is a no-op (never accidentally re-hides).
    func revealAmounts() {
        let hero = element(A11y.Overview.netWorth)
        XCTAssertTrue(hero.waitForExistence(timeout: 5), "Net-worth hero not found")
        // Censored renders "••••••" with a VoiceOver label of "hidden" (AmountText).
        if hero.label.contains("•") || hero.label.localizedCaseInsensitiveContains("hidden") {
            element(A11y.Overview.censorToggle).tap()
        }
    }

    /// The net-worth hero's revealed value as shown. Switches to Overview and reveals first, so it's
    /// safe to call from any tab. Used to assert a write in one tab changed the total shown in
    /// another (freshness) and that it survived relaunch.
    func revealedNetWorth() -> String {
        selectTab("Overview")
        revealAmounts()
        return element(A11y.Overview.netWorth).label
    }

    /// Today's day-of-month, computed the same way the app's CalendarStore does (`Calendar.current`),
    /// so a test can address today's grid cell.
    var todayDayNumber: Int {
        Calendar.current.component(.day, from: Date())
    }

    /// A source row's revealed value on Overview, as shown. Used to assert a balance changed (or did
    /// NOT change) without parsing locale-formatted VND — we compare the string before/after.
    func revealedSourceRow(_ name: String) -> String {
        selectTab("Overview")
        revealAmounts()
        let row = element(A11y.Overview.sourceRow(name))
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Source row '\(name)' not found")
        return row.label
    }

    /// Whether a transaction with the given note is listed under today in the Calendar day detail.
    /// `TransactionRow` renders the note as its title, so a unique note is a robust handle that needs
    /// no amount parsing. Returns false (not a failure) when today has no activity at all.
    /// NOTE: the grid excludes transfers (`CalendarMath.dailyNet`); backfilled expenses/income are
    /// ordinary entries and DO appear here (ADR-0012).
    func calendarTodayContains(note: String) -> Bool {
        selectTab("Calendar")
        let today = element(A11y.Calendar.day(todayDayNumber))
        guard today.waitForExistence(timeout: 5) else { return false }
        today.tap()
        return staticTexts[note].waitForExistence(timeout: 5)
    }

    /// Whether a transaction with the given note appears in a source's Account History, opened by
    /// tapping its Overview row. Pops back to the Overview root afterwards so the nav stack is clean.
    /// Leaves the source's history pushed on the Overview stack — call it LAST before a relaunch or
    /// end of test (a relaunch resets the stack). Scrolls to find the row because seed data can be
    /// future-dated, pushing a freshly-added (now-dated) entry below the first screen.
    func accountHistoryContains(_ source: String, note: String) -> Bool {
        selectTab("Overview")
        // Tap the row's button specifically — the NavigationLink surfaces as a button, and a generic
        // `.any` match can return a non-hittable wrapper that doesn't navigate.
        let row = buttons[A11y.Overview.sourceRow(source)]
        guard row.waitForExistence(timeout: 5) else { return false }
        row.tap()
        guard navigationBars[source].waitForExistence(timeout: 5) else { return false }
        let target = staticTexts[note]
        var tries = 0
        while !target.exists && tries < 8 {
            swipeUp()
            tries += 1
        }
        return target.exists
    }

    /// An envelope's remaining amount as shown on Config → Envelopes (never censored). Navigates
    /// there if not already, so it's safe to call repeatedly to compare before/after a spend.
    func envelopeRemaining(_ name: String) -> String {
        selectTab("Config")
        if !navigationBars["Envelopes"].exists {
            element(A11y.Config.envelopes).tap()
        }
        let cell = element(A11y.Envelope.remaining(name))
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "Envelope '\(name)' remaining not found")
        return cell.label
    }

    /// Open a fresh transaction form via the Calendar's floating **+** — the only add-transaction
    /// entry point since the Add tab was replaced by the Charts tab. The Calendar selects today on
    /// load, so the new transaction is prefilled with today's date. Leaves the form on screen.
    func openNewTransaction(file: StaticString = #filePath, line: UInt = #line) {
        selectTab("Calendar")
        tapElement(A11y.Calendar.addTransaction, file: file, line: line)
        XCTAssertTrue(navigationBars["Add transaction"].waitForExistence(timeout: 5),
                      "Transaction form did not open from the Calendar +", file: file, line: line)
    }

    /// Assert the transaction form dismissed back to the Calendar (its floating + is showing again).
    /// Replaces the old "returned to the Input hub" check now that the form is a Calendar sheet.
    func assertReturnedToCalendar(_ message: String = "Transaction form did not dismiss back to the Calendar",
                                  file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element(A11y.Calendar.addTransaction).waitForExistence(timeout: 5),
                      message, file: file, line: line)
    }

    /// Open Config → Update balances (the Reconcile screen moved here from the removed Add tab).
    func openReconcile(file: StaticString = #filePath, line: UInt = #line) {
        selectTab("Config")
        tapElement(A11y.Config.reconcile, file: file, line: line)
        XCTAssertTrue(navigationBars["Update balances"].waitForExistence(timeout: 5),
                      "Update balances did not open from Config", file: file, line: line)
    }

    /// Tap a root tab by its visible title ("Overview", "Goals", "Calendar", "Charts", "Config").
    /// Tabs use SwiftUI's `Tab(_:systemImage:value:)`, which does not surface a custom identifier,
    /// so the title is the stable handle here.
    @discardableResult
    func selectTab(_ title: String) -> XCUIElement {
        let tab = tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab '\(title)' not found")
        tab.tap()
        return tab
    }

    /// First element with the given identifier, regardless of element type (button, textField,
    /// staticText, other). SwiftUI maps a `.accessibilityIdentifier` onto different XCUI types
    /// depending on the control, so match across all of them.
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Type into a text field found by identifier, clearing any existing value first.
    /// Numeric fields in a Form don't show a "Clear text" affordance, so clear by sending
    /// `delete` keystrokes — robust across keyboard types.
    ///
    /// Amount fields group thousands live (see `AmountGroupingUITests`), so every keystroke triggers
    /// a reformat and a single rapid `typeText` burst can drop *or duplicate* a digit on a slow CI
    /// runner (seen as "250,000" or "252,500,000" for "2500000"). To stay both fast and reliable we
    /// burst-type once, then verify the field's digits; if they don't match we clear and retype
    /// one character at a time, re-verifying — looping until the field is exactly right (or we run
    /// out of attempts). The common case is a single burst; char-by-char across the whole suite
    /// timed the UI job out on CI, so it's only the fallback.
    func typeInField(_ identifier: String, _ text: String) {
        let field = textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Field '\(identifier)' not found")
        field.tap()
        let wantDigits = text.filter(\.isNumber)

        for attempt in 0..<3 {
            clearTextField(field)
            if attempt == 0 {
                field.typeText(text)
            } else {
                for character in text { field.typeText(String(character)) }
            }
            let gotDigits = (field.value as? String ?? "").filter(\.isNumber)
            if wantDigits.isEmpty || gotDigits == wantDigits { return }
        }
    }

    /// Clears a focused text field by sending deletes (numeric Forms have no "Clear text" affordance).
    private func clearTextField(_ field: XCUIElement) {
        guard let existing = field.value as? String, !existing.isEmpty, existing != "0" else { return }
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count + 2))
    }

    /// Wait for an element (matched across all XCUI types by `identifier`) to exist, then tap it.
    /// `element(_:).tap()` on its own does NOT wait, so tapping right after a tab switch races the
    /// hub's first render — seen on CI as "No matches found for input.backfill" (`BackfillUITests`).
    /// Also scrolls a below-the-fold row into view first (see `scrollToHittable`), so a row a lazy
    /// list hasn't materialised — the Config Debug section's `config.seedSample` once the Config list
    /// grew past one screen — is found and tapped instead of timing out as "not found".
    func tapElement(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = element(identifier)
        XCTAssertTrue(scrollToHittable(target), "Element '\(identifier)' not found", file: file, line: line)
        target.tap()
    }

    /// Make `element` hittable, scrolling the screen up to a few times to pull a below-the-fold row
    /// into a lazy List/Form's rendered — and therefore *accessible* — window. A plain existence wait
    /// never sees a row the lazy list hasn't materialised yet, so a tap target near the bottom of a
    /// long list (e.g. the Config Debug section) reads as "not found" without this. Returns whether
    /// the element exists at the end; the caller still taps (XCUI auto-scrolls on tap), so this only
    /// ever *adds* a chance to reveal the element — it never blocks a tap that would have worked.
    @discardableResult
    func scrollToHittable(_ element: XCUIElement, timeout: TimeInterval = 5, scrolls: Int = 6) -> Bool {
        if element.waitForExistence(timeout: timeout) && element.isHittable { return true }
        for _ in 0..<scrolls {
            if element.exists && element.isHittable { return true }
            swipeUp()
        }
        return element.exists
    }

    /// Drive a SwiftUI `Toggle` (surfaces as a switch) identified by `identifier` to `on`. Reads its
    /// current value first so it only taps when a change is needed — idempotent across runs — and
    /// verifies the resulting state (a tap on the row label doesn't always flip the binding).
    func setToggle(_ identifier: String, on: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let toggle = switches[identifier]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Toggle '\(identifier)' not found", file: file, line: line)
        for _ in 0..<3 {
            if ((toggle.value as? String) == "1") == on { return }
            // A plain `.tap()` on a SwiftUI Toggle in a Form often lands on the row label and doesn't
            // flip it; tapping the switch's own coordinate (where the knob sits) does.
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        XCTAssertEqual(toggle.value as? String, on ? "1" : "0",
                       "Toggle '\(identifier)' would not move to \(on)", file: file, line: line)
    }

    /// Drive a SwiftUI `Picker` (menu/navigation style) identified by `identifier` to `option`.
    /// Taps the picker, then taps the option by its visible label wherever it surfaces.
    func selectPickerOption(_ identifier: String, _ option: String) {
        let picker = element(identifier)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Picker '\(identifier)' not found")
        picker.tap()
        // The menu option surfaces as a button or a static text depending on the control style,
        // so poll for whichever appears and tap it. A cold CI simulator animates the menu slowly;
        // the old code waited only on the button and then tapped the static text with no wait,
        // which flaked as "No matches found" on slow runners.
        let optionButton = buttons[option].firstMatch
        let optionText = staticTexts[option].firstMatch
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if optionButton.exists { optionButton.tap(); return }
            if optionText.exists { optionText.tap(); return }
            usleep(100_000)
        }
        XCTFail("Picker option '\(option)' did not appear")
    }
}
