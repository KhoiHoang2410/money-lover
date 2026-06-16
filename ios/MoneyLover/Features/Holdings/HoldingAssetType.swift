import Foundation

/// The kind of asset being added on the Holding form. Drives which fields show: Gold takes a
/// quantity + unit (chỉ/lượng); Stock takes a share count + a HOSE/HNX symbol.
enum HoldingAssetType: String, CaseIterable, Identifiable {
    case gold
    case stock

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gold: "Gold"
        case .stock: "Stock"
        }
    }

    var iconName: String {
        switch self {
        case .gold: "seal.fill"
        case .stock: "chart.line.uptrend.xyaxis"
        }
    }
}
