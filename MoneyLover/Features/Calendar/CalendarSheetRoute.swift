import Foundation

/// What the Calendar presents in its single transaction sheet: a new entry on a date (feat 1) or
/// an edit of an existing one (feat 5). One enum-driven sheet avoids the multiple-`.sheet` conflict.
enum CalendarSheetRoute: Identifiable {
    case add(Date)
    case edit(Transaction)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let transaction): transaction.id.uuidString
        }
    }
}
