import Foundation

/// A snapshot of conversion rates into the base currency (VND).
struct Rates: Sendable, Equatable {
    /// VND per 1 unit of the given currency (VND maps to 1).
    var fx: [Currency: Decimal]
    /// VND per chỉ of SJC gold.
    var goldPerChi: Decimal
    /// VND per share, by HOSE ticker.
    var stock: [String: Decimal]

    static let empty = Rates(fx: [.vnd: 1], goldPerChi: 0, stock: [:])

    /// VND per 1 unit of `currency` (always 1 for VND).
    func fxRate(_ currency: Currency) -> Decimal {
        currency == .vnd ? 1 : (fx[currency] ?? 0)
    }
}
