import Foundation

/// What the Holdings list presents in its single form sheet: a new holding, or an edit of an existing
/// one (feat: tap a row to update its opening quantity). One enum-driven sheet avoids `.sheet` conflicts.
enum HoldingFormRoute: Identifiable {
    case add
    case edit(Source)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let holding): holding.id.uuidString
        }
    }
}
