import Foundation

/// A selectable Vietnamese-market stock symbol for the Holding picker (ADR-0001: bundled, offline).
struct VNTicker: Identifiable, Hashable, Sendable, Codable {
    /// The short HOSE/HNX symbol, e.g. "VNG", "FPT".
    let symbol: String
    /// The company short name, e.g. "VNG Corporation".
    let name: String
    /// "HOSE" or "HNX".
    let exchange: String

    var id: String { symbol }
}
