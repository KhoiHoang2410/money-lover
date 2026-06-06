import Foundation

/// The direction of an Invest transaction: buying units of a Holding with an Account's cash,
/// or selling units back into an Account. See ADR-0010.
enum TradeDirection: String, Codable, Sendable, CaseIterable, Identifiable {
    /// Account pays `quantity × unit price`; the Holding's quantity increases.
    case buy
    /// The Holding's quantity decreases; the Account receives `quantity × unit price`.
    case sell

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buy: "Buy"
        case .sell: "Sell"
        }
    }
}
