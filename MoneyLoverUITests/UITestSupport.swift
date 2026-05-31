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
    func typeInField(_ identifier: String, _ text: String) {
        let field = textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "Field '\(identifier)' not found")
        field.tap()
        if let existing = field.value as? String, !existing.isEmpty, existing != "0" {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count + 2)
            field.typeText(deletes)
        }
        field.typeText(text)
    }

    /// Drive a SwiftUI `Picker` (menu/navigation style) identified by `identifier` to `option`.
    /// Taps the picker, then taps the option by its visible label wherever it surfaces.
    func selectPickerOption(_ identifier: String, _ option: String) {
        let picker = element(identifier)
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Picker '\(identifier)' not found")
        picker.tap()
        let optionButton = buttons[option].firstMatch
        if optionButton.waitForExistence(timeout: 3) {
            optionButton.tap()
        } else {
            staticTexts[option].firstMatch.tap()
        }
    }
}
