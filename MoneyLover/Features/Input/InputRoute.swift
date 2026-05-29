import Foundation

/// Destinations from the Input hub. Voice arrives in a later slice.
enum InputRoute: Hashable {
    /// The merged Expense / Income / Transfer entry form.
    case transaction
    case voice
    case reconcile
    case backfill
}
