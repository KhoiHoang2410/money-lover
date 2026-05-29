import SwiftUI

/// One calendar day: the day number and its net (+/−), color-coded.
struct DayCell: View {
    let day: Int
    let net: Money?

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
    }
}
