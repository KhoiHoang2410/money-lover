import SwiftUI

/// A Goal shown as an Asset on the Overview: icon, name, and its funded VND balance.
struct GoalAssetRow: View {
    let goal: Goal
    let balance: Money
    var censored: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: goal.iconName)
                .foregroundStyle(Theme.Palette.pinkDeep)
                .frame(width: Theme.Layout.minTap, height: Theme.Layout.minTap)
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.name).bold()
                Text("Goal").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            AmountText(money: balance, censored: censored)
                .bold()
                .foregroundStyle(Theme.Palette.ink)
        }
        .padding(.vertical, 4)
    }
}
