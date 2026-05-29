import Foundation

/// Net-worth totals, all in base currency (VND). `debt` is negative; `net = asset + debt`.
struct NetWorth: Sendable, Equatable {
    let asset: Money
    let debt: Money
    let net: Money
}
