import Foundation

/// The single destination type for the Overview navigation stack, keyed by stable IDs.
///
/// One route type → one `navigationDestination(for:)` (registered once per type, per the SwiftUI
/// navigation guidance), instead of the previous two stacked typed destinations. The actual
/// BUG-001 cause was a non-hit-testable `Spacer()` in the rows (fixed with `.contentShape` in
/// `OverviewContent`); this route is kept as the cleaner navigation shape.
enum OverviewRoute: Hashable {
    case account(UUID)
    case goal(UUID)
}
