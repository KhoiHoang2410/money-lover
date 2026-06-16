import Foundation

/// A Goal's progress: expected-by-today vs actual, the ahead/behind percentage, and target fraction.
struct GoalProgress: Sendable, Equatable {
    let expected: Money
    let actual: Money
    /// actual ÷ expected − 1 (positive = ahead of plan, negative = behind). 0 when nothing is due yet.
    let pct: Double
    /// actual ÷ target, clamped to 0...1 (for the progress ring).
    let fractionOfTarget: Double
}
