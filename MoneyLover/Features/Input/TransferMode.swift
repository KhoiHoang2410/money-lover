import Foundation

/// The three transfer flows offered in the UI.
enum TransferMode: String, CaseIterable, Identifiable {
    case sameCurrency
    case crossCurrency
    case payCard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sameCurrency: "Same currency"
        case .crossCurrency: "Cross-currency"
        case .payCard: "Pay card"
        }
    }
}
