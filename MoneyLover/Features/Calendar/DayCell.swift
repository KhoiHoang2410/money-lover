import SwiftUI

/// One calendar day: the day number and its net (+/−), color-coded.
struct DayCell: View {
    let day: Int
    let net: Money?
    var isSelected: Bool = false
    var isToday: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text("\(day)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            // Always reserve the diff line so day numbers stay vertically aligned across cells.
            Text(netLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(net?.isNegative == true ? Theme.Palette.bad : Theme.Palette.ok)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(hasNet ? 1 : 0)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .center)
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    // Today reads as a translucent pink tint — distinct from the selected border,
                    // and stacks with it when today is also the selected day.
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isToday ? Theme.Palette.pink.opacity(0.18) : .clear)
                }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Palette.pink, lineWidth: 2)
            }
        }
    }

    private var hasNet: Bool {
        if let net { return net.minorUnits != 0 }
        return false
    }

    private var netLabel: String {
        guard let net, net.minorUnits != 0 else { return " " }
        return net.amount.formatted(.number.notation(.compactName))
    }
}
