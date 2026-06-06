import Foundation

/// What a transaction does. Expense/Income land in slice 02; Transfer in 03; Adjustment in 11;
/// Invest (Buy/Sell of a Holding) in ADR-0010.
enum TransactionKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer
    case adjustment
    /// A Buy or Sell of a Holding: a VND Account (`sourceID`) trades units of a Holding
    /// (`destinationID`). See ADR-0010.
    case invest

    var id: String { rawValue }
}
