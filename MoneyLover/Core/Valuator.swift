import Foundation

/// Converts a source's value into the base currency (VND). Pure — no network.
enum Valuator {
    /// Value of a source in VND, given its current balance and a set of rates.
    /// Accounts/cards convert their balance by FX; holdings use quantity × market price.
    static func valueInVND(source: Source, balance: Money, rates: Rates) -> Money {
        switch source.kind {
        case .account, .creditCard:
            return Money(major: balance.amount * rates.fxRate(source.currency), currency: .vnd)
        case .holding:
            guard let holding = source.holding else { return .zero(.vnd) }
            if let ticker = holding.ticker {
                return Money(major: holding.quantity * (rates.stock[ticker] ?? 0), currency: .vnd)
            }
            let chi = holding.unit == .luong ? holding.quantity * 10 : holding.quantity
            return Money(major: chi * rates.goldPerChi, currency: .vnd)
        }
    }
}
