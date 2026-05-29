import Foundation

/// The raw fields a language model extracts from a spoken expense phrase, before any
/// Swift-side validation. The model never does arithmetic: `amount` is the magnitude it
/// heard in major currency units (e.g. 40000 for "40k"), and people counts stay in `note`.
/// Every field is optional — the model may fail to hear any of them.
struct RawExpenseExtraction: Equatable, Sendable {
    /// Spoken amount in major currency units, already expanded (e.g. "40k" → 40000). May be nil.
    var amount: Double?
    /// ISO currency code the model heard ("VND", "USD"…), case-insensitive. nil ⇒ caller's default.
    var currencyCode: String?
    /// A short human note for the expense, ideally retaining context like "cho 2 người".
    var note: String?
    /// The model's guess at which envelope this belongs to, matched by name in Swift.
    var envelopeName: String?

    init(amount: Double? = nil, currencyCode: String? = nil, note: String? = nil, envelopeName: String? = nil) {
        self.amount = amount
        self.currencyCode = currencyCode
        self.note = note
        self.envelopeName = envelopeName
    }

    /// Nothing was extracted (unparseable input or model failure).
    static let empty = RawExpenseExtraction()
}
