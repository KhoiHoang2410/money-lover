import Foundation

/// Pure filtering of an account's transaction history. A transaction belongs to an account when
/// the account is its source or its destination (so transfers in *and* out appear).
enum TransactionHistory {
    /// Transactions touching `accountID`, within `range` of `asOf`, optionally limited to one
    /// `kind` and matching `search` in the note. Newest-first.
    static func entries(
        transactions: [Transaction],
        accountID: UUID,
        range: HistoryRange,
        kind: TransactionKind? = nil,
        search: String = "",
        asOf: Date = .now,
        calendar: Calendar = .current
    ) -> [Transaction] {
        let lowerBound = range.days.flatMap { calendar.date(byAdding: .day, value: -$0, to: asOf) }
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return transactions
            .filter { $0.sourceID == accountID || $0.destinationID == accountID }
            .filter { lowerBound == nil || $0.date >= lowerBound! }
            .filter { kind == nil || $0.kind == kind }
            .filter { needle.isEmpty || $0.note.lowercased().contains(needle) }
            .sorted { $0.date > $1.date }
    }
}
