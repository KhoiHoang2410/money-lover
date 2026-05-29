import Foundation

/// What a transaction does. Expense/Income land in slice 02; Transfer in 03; Adjustment in 11.
enum TransactionKind: String, Codable, Sendable, CaseIterable, Identifiable {
    case expense
    case income
    case transfer
    case adjustment

    var id: String { rawValue }
}
