import Foundation

/// A named virtual budget bucket. Allocations and balances are in the base currency (VND).
/// Exactly one envelope is the Reserve (the month-end catch-all).
struct Envelope: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var iconName: String
    /// Planned amount for the month, in base currency (VND).
    var allocation: Money
    /// Accumulated amount swept in from past months (meaningful for the Reserve).
    var carried: Money
    var isReserve: Bool

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        allocation: Money,
        carried: Money = .zero(.vnd),
        isReserve: Bool = false
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.allocation = allocation
        self.carried = carried
        self.isReserve = isReserve
    }
}
