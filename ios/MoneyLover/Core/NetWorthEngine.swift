import Foundation

/// Aggregates sources into net-worth totals in VND. Pure.
enum NetWorthEngine {
    /// - Parameters:
    ///   - entries: each source paired with its current balance.
    ///   - goalBalances: the VND balance of each Goal, counted as an Asset (ADR-0007).
    static func compute(
        entries: [(source: Source, balance: Money)],
        rates: Rates,
        goalBalances: [Money] = []
    ) -> NetWorth {
        var asset = 0
        var debt = 0
        for entry in entries {
            let value = Valuator.valueInVND(source: entry.source, balance: entry.balance, rates: rates).minorUnits
            if entry.source.kind.isLiability {
                debt += value
            } else {
                asset += value
            }
        }
        asset += goalBalances.reduce(0) { $0 + $1.minorUnits }
        return NetWorth(
            asset: Money(minorUnits: asset, currency: .vnd),
            debt: Money(minorUnits: debt, currency: .vnd),
            net: Money(minorUnits: asset + debt, currency: .vnd)
        )
    }
}
