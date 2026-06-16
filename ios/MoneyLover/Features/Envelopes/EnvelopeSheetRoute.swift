import Foundation

/// What the Envelopes list presents in its single sheet: add a new envelope, edit an existing one
/// (feat: tap a row to adjust its caps), or browse the starter set. One enum-driven sheet avoids
/// `.sheet` conflicts.
enum EnvelopeSheetRoute: Identifiable {
    case add
    case edit(Envelope)
    case starter

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let envelope): envelope.id.uuidString
        case .starter: "starter"
        }
    }
}
