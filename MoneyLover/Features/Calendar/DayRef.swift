import Foundation

/// Identifies a specific day for navigation to its detail.
struct DayRef: Hashable {
    let year: Int
    let month: Int
    let day: Int
}
