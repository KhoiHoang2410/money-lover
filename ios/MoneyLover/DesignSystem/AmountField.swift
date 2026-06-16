import SwiftUI
import UIKit

/// The single standard wrapper for **every numeric input** in the app — amounts, balances, prices,
/// rates, quantities, caps. Bind a `Decimal`; the field owns all decoration: the decimal keyboard,
/// trailing alignment, and live locale grouping separators as the user types (e.g. "1,000,000")
/// via `AmountInputFormatter`, keeping the bound value exact. Callers never touch the display string
/// or wire up `.onChange` formatting — they pass the value and (optionally) the currency's fraction
/// digits, then wrap this in a `LabeledContent` (or any row) for the leading label.
///
/// Why a `String` isn't bound out: `TextField(value:format:)` with `.number` only re-groups on
/// commit/blur, so it never groups mid-edit. This drives a `TextField(text:)` through the formatter
/// on every keystroke and parses back to the caller's `Decimal`. New numeric fields MUST use this —
/// see `docs/guidelines/engineering.md` §4.
struct AmountField<Focus: Hashable>: View {
    private let placeholder: LocalizedStringKey
    @Binding private var value: Decimal
    private let fractionDigits: Int
    private let keyboard: UIKeyboardType
    private let accessibilityID: String?
    /// When the host screen drives focus with `@FocusState`, pass its binding + this field's tag so
    /// the field auto-focuses / advances. Most screens leave both nil (see the convenience init).
    private let focusState: FocusState<Focus?>.Binding?
    private let focusTag: Focus?

    @State private var text = ""

    /// Focus-driven field (host owns a `@FocusState`). `Focus` is inferred from `focusTag`.
    init(
        _ placeholder: LocalizedStringKey,
        value: Binding<Decimal>,
        fractionDigits: Int = 2,
        keyboard: UIKeyboardType = .decimalPad,
        accessibilityID: String? = nil,
        focusState: FocusState<Focus?>.Binding,
        focusTag: Focus
    ) {
        self.placeholder = placeholder
        self._value = value
        self.fractionDigits = fractionDigits
        self.keyboard = keyboard
        self.accessibilityID = accessibilityID
        self.focusState = focusState
        self.focusTag = focusTag
    }

    var body: some View {
        decorated
            .keyboardType(keyboard)
            .multilineTextAlignment(.trailing)
            .onChange(of: text) { _, newValue in
                // Re-group in onChange (not the binding setter), else SwiftUI drops the mid-keystroke
                // reformat. Idempotent: feeding the formatted string back in yields the same string.
                let formatted = formatter.format(newValue)
                if formatted != newValue { text = formatted }
                value = formatter.value(formatted)
            }
            .onChange(of: fractionDigits) { _, _ in
                // A currency switch changes the allowed fraction digits — re-render the display.
                text = formatter.display(for: value)
            }
            .onChange(of: value) { _, newValue in
                // External change (edit-mode load, programmatic reset): re-render the text, unless the
                // field already represents this value (don't clobber the user mid-keystroke).
                if formatter.value(text) != newValue { text = formatter.display(for: newValue) }
            }
            .onAppear { if text.isEmpty { text = formatter.display(for: value) } }
    }

    @ViewBuilder private var decorated: some View {
        let field = TextField(placeholder, text: $text)
            .accessibilityIdentifier(accessibilityID ?? "")
        if let focusState, let focusTag {
            field.focused(focusState, equals: focusTag)
        } else {
            field
        }
    }

    private var formatter: AmountInputFormatter {
        AmountInputFormatter(maximumFractionDigits: fractionDigits)
    }
}

extension AmountField where Focus == Int {
    /// Convenience for the common case: a numeric field the host screen doesn't drive focus for.
    init(
        _ placeholder: LocalizedStringKey,
        value: Binding<Decimal>,
        fractionDigits: Int = 2,
        keyboard: UIKeyboardType = .decimalPad,
        accessibilityID: String? = nil
    ) {
        self.placeholder = placeholder
        self._value = value
        self.fractionDigits = fractionDigits
        self.keyboard = keyboard
        self.accessibilityID = accessibilityID
        self.focusState = nil
        self.focusTag = nil
    }
}

#Preview {
    @Previewable @State var amount: Decimal = 1_250_000
    @Previewable @State var rate: Decimal = 0
    Form {
        LabeledContent("Amount") { AmountField("Amount", value: $amount) }
        LabeledContent("Rate") { AmountField("Rate", value: $rate, fractionDigits: 6) }
    }
}
