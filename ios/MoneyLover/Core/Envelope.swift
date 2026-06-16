import Foundation

/// A named virtual budget bucket. Allocations and balances are in the base currency (VND).
/// Exactly one envelope is the Reserve (the month-end catch-all).
struct Envelope: Identifiable, Hashable, Sendable, Codable {
    let id: UUID
    var name: String
    var iconName: String
    /// Planned amount for the month, in base currency (VND).
    var allocation: Money
    /// Accumulated amount swept in from past months (meaningful for the Reserve).
    var carried: Money
    var isReserve: Bool
    /// Optional spending cap for the current calendar week (VND). Nil ⇒ no weekly cap.
    var weeklyCap: Money?
    /// Optional spending cap for the current calendar month (VND). Nil ⇒ no monthly cap.
    var monthlyCap: Money?

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        allocation: Money,
        carried: Money = .zero(.vnd),
        isReserve: Bool = false,
        weeklyCap: Money? = nil,
        monthlyCap: Money? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.allocation = allocation
        self.carried = carried
        self.isReserve = isReserve
        self.weeklyCap = weeklyCap
        self.monthlyCap = monthlyCap
    }
}
