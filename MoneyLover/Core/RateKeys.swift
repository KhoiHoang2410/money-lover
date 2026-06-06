import Foundation

/// Derives the Rate keys a `Source` needs so its value resolves into VND. Adding a foreign-currency
/// Account, or a gold/stock Holding, introduces a price that must exist in the rate table (else the
/// Valuator degrades it to ₫0). Pure so the mapping is unit-tested without persistence.
///
/// Keys mirror `RatesRepository`'s scheme: `"fx.USD"`, `"fx.SGD"`, `"gold"`, `"stock.<TICKER>"`.
enum RateKeys {
    /// The rate keys that must exist for `source` to be valued in VND (empty for a VND Account/card).
    static func required(for source: Source) -> [String] {
        switch source.kind {
        case .account, .creditCard:
            source.currency == .vnd ? [] : ["fx.\(source.currency.rawValue)"]
        case .holding:
            if let ticker = source.holding?.ticker, !ticker.isEmpty {
                ["stock.\(ticker)"]
            } else {
                ["gold"]
            }
        }
    }
}
