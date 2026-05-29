import SwiftUI

/// One transaction line: kind icon, note/title, an optional date or "backfilled" subtitle, and
/// the amount (income in green). Shared by account history and the calendar day detail.
struct TransactionRow: View {
    let transaction: Transaction
    var showsDate: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Palette.pinkDeep)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).bold()
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(transaction.amount.amount, format: .currency(code: transaction.amount.currency.rawValue))
                .bold()
                .foregroundStyle(transaction.kind == .income ? Theme.Palette.ok : Theme.Palette.ink)
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        transaction.note.isEmpty ? transaction.kind.rawValue.capitalized : transaction.note
    }

    private var subtitle: String {
        let kind = transaction.kind.rawValue.capitalized
        let label = transaction.affectsBalance ? kind : "\(kind) · backfilled"
        return showsDate ? "\(label) · \(transaction.date.formatted(.dateTime.day().month().year()))" : label
    }

    private var icon: String {
        switch transaction.kind {
        case .expense: "minus.circle.fill"
        case .income: "plus.circle.fill"
        case .transfer: "arrow.left.arrow.right"
        case .adjustment: "slider.horizontal.3"
        }
    }
}
