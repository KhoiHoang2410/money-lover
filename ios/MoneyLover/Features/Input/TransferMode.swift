import Foundation

/// The transfer flows offered in the UI.
enum TransferMode: String, CaseIterable, Identifiable {
    /// A move between the owner's own Sources. Same-currency shows a single Amount; cross-currency
    /// (the two Sources differ in currency) reveals Amount out / Amount in + Rate, with a computed
    /// Fee — the form decides which from the picked Sources, not a separate mode.
    case transfer
    case payCard
    /// Fund a Goal: a VND Account → Goal contribution (ADR-0007). One-way — there's no undo here.
    case goal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .transfer: "Transfer"
        case .payCard: "Pay card"
        case .goal: "Goal"
        }
    }
}
