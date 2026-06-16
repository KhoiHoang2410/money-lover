import Foundation

/// A validated, edit-ready expense parsed from voice. Always shown on the review screen for
/// confirmation before it becomes a `Transaction` — it is never saved automatically.
///
/// `amount` is optional: an unparseable or invalid spoken amount yields `nil` so the review
/// screen prompts the user to enter it, rather than guessing. The source is never inferred —
/// the user always picks which Source the expense came from.
struct ExpenseDraft: Equatable, Sendable {
    /// The validated amount, or nil when the model heard no usable number.
    var amount: Money?
    /// Free-text note, retaining spoken context (e.g. "bánh mì cho 2 người").
    var note: String
    /// The guessed Envelope, matched from the model's text by name. nil ⇒ user picks.
    var envelopeID: UUID?

    init(amount: Money? = nil, note: String = "", envelopeID: UUID? = nil) {
        self.amount = amount
        self.note = note
        self.envelopeID = envelopeID
    }

    /// Nothing usable was parsed.
    static let empty = ExpenseDraft()
}
