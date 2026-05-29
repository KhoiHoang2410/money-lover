import SwiftUI

/// One calendar day: the day number and its net (+/−), color-coded.
struct DayCell: View {
    let day: Int
    let net: Money?
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text("\(day)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if let net, net.minorUnits != 0 {
                Text(net.amount, format: .number.notation(.compactName))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(net.isNegative ? Theme.Palette.bad : Theme.Palette.ok)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .topLeading)
        .padding(4)
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 10))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.Palette.pink, lineWidth: 2)
            }
        }
    }
}
