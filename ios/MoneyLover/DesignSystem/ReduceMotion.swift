import SwiftUI

/// The owner's app-level "Reduce motion" preference (set on the Appearance screen).
/// Views combine it with the system `accessibilityReduceMotion` to decide whether to animate.
extension EnvironmentValues {
    @Entry var reduceMotionPreference: Bool = false
}
