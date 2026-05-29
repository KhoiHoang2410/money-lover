import Foundation

/// Errors raised by `Money` arithmetic.
enum MoneyError: Error, Equatable {
    /// Two `Money` values of different currencies were combined.
    case currencyMismatch(Currency, Currency)
}
