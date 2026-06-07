import Foundation

/// What the Sources list presents in its single form sheet: a new source, or an edit of an existing
/// one (feat: tap a row to update its opening balance). One enum-driven sheet avoids `.sheet` conflicts.
enum SourceFormRoute: Identifiable {
    case add
    case edit(Source)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let source): source.id.uuidString
        }
    }
}
