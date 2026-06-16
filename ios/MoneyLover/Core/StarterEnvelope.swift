import Foundation

/// One suggested Envelope in the hard-coded **Starter envelopes** set (feat 4): a name + icon only,
/// no Allocation. The owner picks any subset to seed their Envelopes list. Distinct from the
/// recurring *Allocation template* (see CONTEXT.md).
struct StarterEnvelope: Identifiable, Hashable, Sendable {
    let name: String
    let iconName: String
    /// The single member intended as the Reserve; becomes the Reserve on apply only if none exists.
    let isReserveDefault: Bool

    var id: String { name }

    init(_ name: String, _ iconName: String, isReserveDefault: Bool = false) {
        self.name = name
        self.iconName = iconName
        self.isReserveDefault = isReserveDefault
    }

    /// The single supported starter set — a sensible spread for a typical owner.
    static let catalog: [StarterEnvelope] = [
        StarterEnvelope("Food & Dining", "fork.knife"),
        StarterEnvelope("Groceries", "cart.fill"),
        StarterEnvelope("Transport", "car.fill"),
        StarterEnvelope("Rent / Housing", "house.fill"),
        StarterEnvelope("Utilities", "bolt.fill"),
        StarterEnvelope("Phone & Internet", "wifi"),
        StarterEnvelope("Health", "cross.case.fill"),
        StarterEnvelope("Shopping", "bag.fill"),
        StarterEnvelope("Entertainment", "gamecontroller.fill"),
        StarterEnvelope("Coffee", "cup.and.saucer.fill"),
        StarterEnvelope("Education", "book.fill"),
        StarterEnvelope("Savings", "star.fill", isReserveDefault: true)
    ]

    /// Case-insensitive, trimmed key used to gray out a starter whose name already exists.
    static func key(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
