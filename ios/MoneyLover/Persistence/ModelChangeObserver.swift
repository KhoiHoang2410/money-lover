import Foundation
import SwiftData

/// Re-runs a store's reload whenever any `ModelContext` saves, so view state stays fresh after a
/// write committed in any tab — no manual `.onAppear { load() }`, no relaunch (ADR-0009). A store
/// owns one; the subscription is torn down when the store (and thus this observer) deallocates.
///
/// `ModelContext.didSave` is posted only on `save()`, never on a `fetch`, so the reload it triggers
/// cannot re-enter: load → fetch → (no save) → no notification.
@MainActor
final class ModelChangeObserver {
    private var task: Task<Void, Never>?

    /// Begins observing. `reload` runs on the main actor after each save.
    func observe(_ reload: @escaping @MainActor () -> Void) {
        task?.cancel()
        task = Task {
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                reload()
            }
        }
    }

    deinit { task?.cancel() }
}
