import SwiftUI

/// Icon + name label for a `Source` inside a menu `Picker`. Shows the source's bundled bank/brand
/// logo when present, otherwise its SF Symbol — so accounts, cards and holdings are recognizable at
/// a glance while picking a From/Into/Holding option, not just by name.
struct SourcePickerLabel: View {
    let source: Source

    var body: some View {
        Label {
            Text(source.name)
        } icon: {
            if let logo = source.logoAsset {
                Image(logo).resizable().scaledToFit()
            } else {
                Image(systemName: source.iconName)
            }
        }
    }
}

/// Icon + name label for an `Envelope` inside a menu `Picker`, mirroring the envelope's row icon.
struct EnvelopePickerLabel: View {
    let envelope: Envelope

    var body: some View {
        Label(envelope.name, systemImage: envelope.iconName)
    }
}
