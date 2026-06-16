import Foundation

/// Failures surfaced by the expense parser.
enum ExpenseParsingError: LocalizedError {
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .modelUnavailable: "On-device understanding isn't available on this device."
        }
    }
}
