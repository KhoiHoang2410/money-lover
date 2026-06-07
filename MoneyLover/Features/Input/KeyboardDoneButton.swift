import SwiftUI

/// Adds an **OK** accessory button above the keyboard that accepts the current value and dismisses
/// the keyboard. The number/decimal pads have no return key of their own, so without this an amount
/// field can only be dismissed by tapping away — this gives every input a clear "done" affordance.
///
/// Uses `resignFirstResponder` rather than a bound `@FocusState` so one modifier covers a whole form
/// regardless of which field is focused.
private struct KeyboardDoneButton: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("OK") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                }
                .accessibilityIdentifier(A11y.Txn.keyboardDone)
            }
        }
    }
}

extension View {
    /// See `KeyboardDoneButton`: an **OK** button above the keyboard that commits and dismisses it.
    func keyboardDoneButton() -> some View { modifier(KeyboardDoneButton()) }
}
