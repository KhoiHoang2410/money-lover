import Foundation

/// The unit a `Holding`'s quantity is measured in.
enum HoldingUnit: String, Codable, Sendable, CaseIterable, Identifiable {
    case chi      // 1 chỉ of gold
    case luong    // 1 lượng = 10 chỉ
    case shares   // stock shares

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chi: "chỉ"
        case .luong: "lượng"
        case .shares: "shares"
        }
    }
}
