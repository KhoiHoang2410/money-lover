import SwiftUI

/// One envelope cap-usage line, e.g. "Week  ₫120,000 / ₫150,000". Turns red with a warning glyph
/// once spend reaches the cap — the glyph keeps it legible without relying on color (accessibility).
struct EnvelopeCapLine: View {
    let label: String
    let spent: Money
    let cap: Money

    private var isOver: Bool { spent.minorUnits >= cap.minorUnits }

    var body: some View {
        Label {
            Text("\(label)  \(spent.formatted) / \(cap.formatted)")
        } icon: {
            Image(systemName: isOver ? "exclamationmark.triangle.fill" : "gauge.with.dots.needle.33percent")
        }
        .font(.caption)
        .foregroundStyle(isOver ? Theme.Palette.bad : .secondary)
    }
}

#Preview {
    VStack(alignment: .leading) {
        EnvelopeCapLine(label: "Week", spent: Money(minorUnits: 120_000, currency: .vnd), cap: Money(minorUnits: 150_000, currency: .vnd))
        EnvelopeCapLine(label: "Month", spent: Money(minorUnits: 1_300_000, currency: .vnd), cap: Money(minorUnits: 1_200_000, currency: .vnd))
    }
    .padding()
}
