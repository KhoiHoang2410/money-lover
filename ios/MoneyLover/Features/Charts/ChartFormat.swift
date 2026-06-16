import Foundation

/// Compact VND labels for chart axes (display only — not money math). VND has a 1:1 minor-unit
/// scale, so `minorUnits` is the đồng value.
enum ChartFormat {
    static func compact(_ money: Money) -> String {
        let value = money.minorUnits
        let sign = value < 0 ? "-" : ""
        let magnitude = abs(value)
        switch magnitude {
        case 1_000_000_000...:
            return "\(sign)₫\(String(format: "%.1f", Double(magnitude) / 1_000_000_000))B"
        case 1_000_000...:
            return "\(sign)₫\(String(format: "%.1f", Double(magnitude) / 1_000_000))M"
        case 1_000...:
            return "\(sign)₫\(String(format: "%.0f", Double(magnitude) / 1_000))k"
        default:
            return "\(sign)₫\(magnitude)"
        }
    }
}
