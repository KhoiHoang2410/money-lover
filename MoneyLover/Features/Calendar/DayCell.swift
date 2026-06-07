import SwiftUI

/// One calendar day: the day number and its net (+/−), color-coded.
struct DayCell: View {
    let day: Int
    let net: Money?
    var isSelected: Bool = false
    var isToday: Bool = false
    /// Saturdays and Sundays render their day number in red to match the weekend columns.
    var isWeekend: Bool = false

    var body: some View {
        VStack(spacing: 3) {
            Text("\(day)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(isWeekend ? Theme.Palette.bad : .primary)
            // Always reserve the diff line so day numbers stay vertically aligned across cells.
            Text(netLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(net?.isNegative == true ? Theme.Palette.bad : Theme.Palette.ok)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(hasNet ? 1 : 0)
        }
        .frame(width: 52, height: 52, alignment: .center)
        .padding(4)
        .background {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    // Today reads as a translucent pink tint — distinct from the selected border,
                    // and stacks with it when today is also the selected day.
                    Circle()
                        .fill(isToday ? Theme.Palette.pink.opacity(0.18) : .clear)
                }
        }
        .overlay {
            if isSelected {
                Circle().strokeBorder(Theme.Palette.pink, lineWidth: 2)
            }
        }
        .frame(maxWidth: .infinity)
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
