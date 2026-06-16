import Foundation

/// Pure helpers for transfers between the owner's own sources.
enum TransferEngine {
    /// The fee of a cross-currency transfer, in the destination currency:
    /// `(amountOut × rate) − amountIn`, where `rate` is destination units per source unit.
    /// A positive result is the cost lost to fees/spread.
    static func fee(amountOut: Money, amountIn: Money, rate: Decimal) -> Money {
        let expected = amountOut.amount * rate
        return Money(major: expected - amountIn.amount, currency: amountIn.currency)
    }
}
