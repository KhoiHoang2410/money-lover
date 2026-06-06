import Foundation

/// Destinations from the Input hub.
enum InputRoute: Hashable {
    /// The merged Expense / Income / Transfer entry form.
    case transaction
    case reconcile
    case backfill
}
