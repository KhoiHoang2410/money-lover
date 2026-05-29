import SwiftUI

/// Lists the transactions on a chosen day.
struct DayDetailScreen: View {
    let store: CalendarStore
    let ref: DayRef

    var body: some View {
        let transactions = store.transactions(onDay: ref.day)
        List {
            ForEach(transactions) { transaction in
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: icon(for: transaction.kind))
                        .foregroundStyle(Theme.Palette.pinkDeep)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.note.isEmpty ? transaction.kind.rawValue.capitalized : transaction.note)
                            .bold()
                        Text(transaction.affectsBalance
                             ? transaction.kind.rawValue.capitalized
                             : "\(transaction.kind.rawValue.capitalized) · backfilled")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(transaction.amount.amount, format: .currency(code: transaction.amount.currency.rawValue))
                        .bold()
                        .foregroundStyle(transaction.kind == .income ? Theme.Palette.ok : Theme.Palette.ink)
                }
            }
        }
        .overlay {
            if transactions.isEmpty {
                ContentUnavailableView("No transactions", systemImage: "calendar")
            }
        }
        .navigationTitle("\(ref.day)/\(ref.month)/\(String(ref.year))")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func icon(for kind: TransactionKind) -> String {
        switch kind {
        case .expense: "minus.circle.fill"
        case .income: "plus.circle.fill"
        case .transfer: "arrow.left.arrow.right"
        case .adjustment: "slider.horizontal.3"
        }
    }
}
