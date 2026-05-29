import Foundation

/// Destinations from the Input hub. Voice arrives in a later slice.
enum InputRoute: Hashable {
    case expense
    case income
    case transfer
    case reconcile
    case backfill
}
