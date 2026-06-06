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
        return app
    }

    /// Launch with an empty store (clear + skip onboarding, no seed). Used to prove that a Source
    /// created after a tab's store first loaded becomes visible there without restarting the app.
    static func launchEmpty() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["UITEST"] = "1"
        app.launchEnvironment["UITEST_EMPTY"] = "1"
        app.launch()
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
    /// NOTE: the grid excludes transfers and informational backfills (`CalendarMath.dailyNet`), so
    /// use `accountHistoryContains` for those.
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

    /// Tap a root tab by its visible title ("Overview", "Goals", "Calendar", "Add", "Config").
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
    /// a reformat and a single rapid `typeText` burst can let a slow CI runner swallow a keystroke
    /// mid-reformat (observed as "250,000" for "2500000"). To stay both fast and reliable we burst-
    /// type once, then verify the field's digits match what we asked for; only if a digit was dropped
    /// do we fall back to the slow one-character-at-a-time path. The common case is a single burst —
    /// char-by-char across the whole suite timed the UI job out on CI.
    func typeInField(_ identifier: String, _ text: String) {
        let field = textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Field '\(identifier)' not found")
        field.tap()
        clearTextField(field)
        field.typeText(text)

        let wantDigits = text.filter(\.isNumber)
        let gotDigits = (field.value as? String ?? "").filter(\.isNumber)
        if !wantDigits.isEmpty, gotDigits != wantDigits {
            clearTextField(field)
            for character in text { field.typeText(String(character)) }
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
    func tapElement(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Element '\(identifier)' not found", file: file, line: line)
        target.tap()
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
