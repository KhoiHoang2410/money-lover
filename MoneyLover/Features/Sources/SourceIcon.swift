import SwiftUI

/// Shows a source's bundled bank logo if present, otherwise its SF Symbol.
struct SourceIcon: View {
    let source: Source

    var body: some View {
        Group {
            if let logo = source.logoAsset {
                Image(logo)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            } else {
                Image(systemName: source.iconName)
                    .font(.title3)
                    .foregroundStyle(Theme.Palette.pinkDeep)
            }
        }
        .frame(width: 36, height: 36)
        .background(Theme.Palette.pinkSoft, in: .rect(cornerRadius: 11))
    }
}
