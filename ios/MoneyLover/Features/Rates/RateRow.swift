import SwiftUI

/// One rate: human label, value, and an auto/manual/stale badge.
struct RateRow: View {
    let record: RateRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.title(for: record.key)).bold()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.value, format: .number)
                .bold()
            badge
        }
    }

    private var isStale: Bool {
        !record.isManual && Date.now.timeIntervalSince(record.fetchedAt) > 2 * 24 * 60 * 60
    }

    @ViewBuilder private var badge: some View {
        if record.isManual {
            tag("manual", color: Theme.Palette.yellowDeep, background: Theme.Palette.yellowSoft)
        } else if isStale {
            tag("stale", color: Theme.Palette.bad, background: Theme.Palette.pinkSoft)
        } else {
            tag("auto", color: Theme.Palette.ok, background: Color(hex: 0xE3F6EC))
        }
    }

    private func tag(_ text: String, color: Color, background: Color) -> some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(background, in: .capsule)
            .foregroundStyle(color)
    }

    private var subtitle: String {
        record.isManual ? "manual override" : "updated \(record.fetchedAt.formatted(.relative(presentation: .named)))"
    }

    static func title(for key: String) -> String {
        switch key {
        case "fx.USD": "USD → VND"
        case "fx.SGD": "SGD → VND"
        case "gold": "SJC gold / chỉ"
        default: key.hasPrefix("stock.") ? "\(key.dropFirst(6)) (HOSE)" : key
        }
    }
}
