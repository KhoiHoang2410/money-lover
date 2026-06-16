import Foundation

/// Pure, locale-aware formatting for amount-entry fields. As the user types digits into a
/// decimal-pad field, this re-groups the integer part with the locale grouping separator
/// (`,` in en-US, `.` in vi-VN — the same separator the Overview shows, e.g. `₫865.062.755`)
/// while preserving an in-progress fraction. The view binds a `Decimal`; this type is the single
/// source of truth mapping raw keystrokes ⇄ display text ⇄ parsed value, so the grouping logic
/// is unit-tested without a running UI.
///
/// Why not `TextField(value:format:)`: `.number` only re-formats the value on commit/blur, so it
/// never groups mid-edit. Driving a `TextField(text:)` through `format(_:)`/`value(_:)` regroups
/// on every keystroke instead.
struct AmountInputFormatter {
    /// Maximum fraction digits kept (0 for VND, 2 for USD/SGD). Negative inputs are clamped to 0.
    let maximumFractionDigits: Int
    let groupingSeparator: String
    let decimalSeparator: String

    init(maximumFractionDigits: Int = 2, locale: Locale = .current) {
        self.init(
            maximumFractionDigits: maximumFractionDigits,
            groupingSeparator: locale.groupingSeparator ?? ",",
            decimalSeparator: locale.decimalSeparator ?? "."
        )
    }

    /// Explicit-separator initializer, for deterministic tests independent of ICU locale data.
    init(maximumFractionDigits: Int, groupingSeparator: String, decimalSeparator: String) {
        self.maximumFractionDigits = max(0, maximumFractionDigits)
        self.groupingSeparator = groupingSeparator
        self.decimalSeparator = decimalSeparator
    }

    /// Re-group raw user input into the display string: strips grouping separators, keeps a single
    /// decimal separator (only when fractions are allowed), groups the integer digits in threes, and
    /// truncates the fraction to `maximumFractionDigits`. Idempotent — feeding its own output back in
    /// yields the same string.
    func format(_ input: String) -> String {
        let parts = decompose(input)
        var intDisplay = group(parts.intDigits)
        if parts.hasSeparator && intDisplay.isEmpty {
            intDisplay = "0" // a bare decimal separator reads as "0.<frac>"
        }
        var result = parts.negative && !intDisplay.isEmpty ? "-" : ""
        result += intDisplay
        if parts.hasSeparator {
            result += decimalSeparator + parts.fraction
        }
        return result
    }

    /// Parse user input (grouped or not) into an exact `Decimal`. Empty/invalid input is `0`.
    func value(_ input: String) -> Decimal {
        let parts = decompose(input)
        if parts.intDigits.isEmpty && parts.fraction.isEmpty { return 0 }
        var s = parts.negative ? "-" : ""
        s += parts.intDigits.isEmpty ? "0" : parts.intDigits
        if !parts.fraction.isEmpty {
            s += "." + parts.fraction
        }
        return Decimal(string: s, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    /// Render a known `Decimal` for the field's initial display (e.g. an edited draft). Zero renders
    /// as the empty string so the field shows its placeholder.
    func display(for value: Decimal) -> String {
        guard value != 0 else { return "" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = maximumFractionDigits
        f.decimalSeparator = decimalSeparator
        let raw = f.string(from: NSDecimalNumber(decimal: value)) ?? ""
        return format(raw)
    }

    // MARK: - Internals

    private func decompose(_ input: String) -> (negative: Bool, intDigits: String, fraction: String, hasSeparator: Bool) {
        let negative = input.first == "-"
        var intPart = ""
        var fracPart = ""
        var seenSeparator = false
        for character in input {
            if String(character) == decimalSeparator {
                seenSeparator = true
                continue
            }
            guard character.isNumber else { continue } // grouping separators, "-", letters: dropped
            if seenSeparator {
                fracPart.append(character)
            } else {
                intPart.append(character)
            }
        }
        let intDigits = normalizeLeadingZeros(intPart)
        let fraction = String(fracPart.prefix(maximumFractionDigits))
        let hasSeparator = seenSeparator && maximumFractionDigits > 0
        return (negative, intDigits, fraction, hasSeparator)
    }

    /// Drop leading zeros but keep a single `0` (so "007" → "7", "0" → "0", "00" → "0", "" → "").
    private func normalizeLeadingZeros(_ digits: String) -> String {
        let trimmed = String(digits.drop { $0 == "0" })
        if trimmed.isEmpty { return digits.isEmpty ? "" : "0" }
        return trimmed
    }

    /// Insert the grouping separator every three digits from the right.
    private func group(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }
        var grouped = ""
        var count = 0
        for character in digits.reversed() {
            if count > 0 && count % 3 == 0 {
                grouped.append(contentsOf: groupingSeparator.reversed())
            }
            grouped.append(character)
            count += 1
        }
        return String(grouped.reversed())
    }
}
