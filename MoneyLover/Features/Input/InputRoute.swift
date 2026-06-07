import Foundation

/// Destinations from the Input hub.
enum InputRoute: Hashable {
    /// The merged Expense / Income / Transfer / Invest entry form. Backfill is a toggle within it.
    case transaction
    case reconcile
}
