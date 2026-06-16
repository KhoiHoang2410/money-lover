import Foundation

/// A currency the app can hold money in. Drives minor-unit scale and formatting.
enum Currency: String, Codable, Sendable, CaseIterable, Identifiable {
    case vnd = "VND"
    case sgd = "SGD"
    case usd = "USD"

    var id: String { rawValue }

    /// Number of fraction digits the currency uses (VND has none).
    var fractionDigits: Int {
        switch self {
        case .vnd: 0
        case .sgd, .usd: 2
        }
    }

    /// How many minor units make one major unit (1 for VND, 100 for SGD/USD).
    var minorUnitScale: Int {
        switch self {
        case .vnd: 1
        case .sgd, .usd: 100
        }
    }
}
