import SwiftUI

/// Horizontal SF Symbol picker for non-bank sources, envelopes, and goals.
struct IconPicker: View {
    @Binding var selection: String

    private let icons = [
        "banknote.fill", "creditcard.fill", "building.columns.fill", "dollarsign.circle.fill",
        "bitcoinsign.circle.fill", "chart.line.uptrend.xyaxis", "wallet.bifold.fill",
        "gift.fill", "airplane", "car.fill", "house.fill", "fork.knife"
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        selection = icon
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: Theme.Layout.minTap, height: Theme.Layout.minTap)
                            .background(
                                selection == icon
                                    ? AnyShapeStyle(Theme.heroGradient)
                                    : AnyShapeStyle(Color.secondary.opacity(0.15)),
                                in: .rect(cornerRadius: 12)
                            )
                            .foregroundStyle(selection == icon ? .white : Theme.Palette.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(icon)
                }
            }
        }
    }
}
