import Foundation

/// What kind of money source this is. Drives net-worth treatment and which fields apply.
enum SourceKind: String, Codable, Sendable, CaseIterable, Identifiable {
    /// A balance held directly in one currency (bank account, Wise balance, cash).
    case account
    /// A credit card — a Liability; spending raises debt, touches no Account until paid.
    case creditCard
    /// Something valued as quantity × market price (gold, stock).
    case holding

    var id: String { rawValue }

    var title: String {
        switch self {
        case .account: "Account"
        case .creditCard: "Credit card"
        case .holding: "Holding"
        }
    }

    /// Whether this source counts as debt (negative) toward net worth.
    var isLiability: Bool { self == .creditCard }
}
