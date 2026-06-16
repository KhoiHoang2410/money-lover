import SwiftUI

/// Displays a money amount, or `••••••` when censored. Keeps a VoiceOver label of "hidden".
struct AmountText: View {
    let money: Money
    var censored: Bool = false

    var body: some View {
        if censored {
            Text(verbatim: "••••••")
                .accessibilityLabel("hidden")
        } else {
            Text(money.amount, format: .currency(code: money.currency.rawValue))
        }
    }
}
