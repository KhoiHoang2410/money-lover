import SwiftUI

/// One source in the Reconcile list: its computed balance, a field for the real balance,
/// and the live diff that would become an Adjustment.
struct ReconcileRow: View {
    let source: Source
    let computed: Money
    @Binding var realBalance: Decimal

    private var diff: Money {
        let entered = Money(major: realBalance, currency: source.currency)
        return (try? entered.subtracting(computed)) ?? .zero(source.currency)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Label(source.name, systemImage: source.iconName)
                    .labelStyle(.titleAndIcon)
                Spacer()
                TextField("Real balance", value: $realBalance, format: .number)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 160)
            }
            HStack {
                Text("Computed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                AmountText(money: computed)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !diff.isZero {
                    Text(diff.isNegative ? "Adjust" : "Adjust +")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AmountText(money: diff)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(diff.isNegative ? Theme.Palette.bad : Theme.Palette.ok)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
