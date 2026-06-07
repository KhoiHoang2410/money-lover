import Foundation

/// The transfer flows offered in the UI.
enum TransferMode: String, CaseIterable, Identifiable {
    case sameCurrency
    case crossCurrency
    case payCard
    /// Fund a Goal: a VND Account → Goal contribution (ADR-0007). One-way — there's no undo here.
    case goal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameCurrency: "Same currency"
        case .crossCurrency: "Cross-currency"
        case .payCard: "Pay card"
        case .goal: "Goal"
        }
    }
}
