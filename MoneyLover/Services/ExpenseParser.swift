import Foundation

/// Turns a spoken transcript into a review-ready `ExpenseDraft`.
///
/// It asks an `ExpenseParsing` model for raw fields, then does all validation in Swift
/// (`draft(from:…)`, a pure function): the amount is rebuilt as exact `Money`, an unusable
/// amount becomes `nil` rather than a guess, and the envelope is matched by name. A model
/// error or empty transcript yields a safe draft that keeps whatever text was spoken.
struct ExpenseParser {
    let model: ExpenseParsing

    init(model: ExpenseParsing) {
        self.model = model
    }

    /// Parses `transcript`, never throwing — failures degrade to a draft the user can complete.
    func parse(
        _ transcript: String,
        envelopes: [Envelope],
        defaultCurrency: Currency = .vnd
    ) async -> ExpenseDraft {
        let raw = (try? await model.extract(from: transcript)) ?? .empty
        return Self.draft(from: raw, transcript: transcript, envelopes: envelopes, defaultCurrency: defaultCurrency)
    }

    /// Pure post-processing: maps raw model fields to a validated draft. No arithmetic is taken
    /// from the model — only the magnitude it heard, rebuilt as exact `Money` here.
    static func draft(
        from raw: RawExpenseExtraction,
        transcript: String,
        envelopes: [Envelope],
        defaultCurrency: Currency = .vnd
    ) -> ExpenseDraft {
        let currency = raw.currencyCode
            .flatMap { Currency(rawValue: $0.uppercased()) } ?? defaultCurrency

        let amount = Self.validatedAmount(raw.amount, currency: currency)

        let trimmedNote = raw.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = (trimmedNote?.isEmpty == false ? trimmedNote : nil)
            ?? transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        let envelopeID = Self.matchEnvelope(named: raw.envelopeName, in: envelopes)?.id

        return ExpenseDraft(amount: amount, note: note, envelopeID: envelopeID)
    }

    /// Accepts only a finite, strictly positive magnitude; anything else is dropped to nil.
    private static func validatedAmount(_ value: Double?, currency: Currency) -> Money? {
        guard let value, value.isFinite, value > 0 else { return nil }
        return Money(major: Decimal(value), currency: currency)
    }

    /// Case-insensitive name match: exact first, then either-direction substring.
    private static func matchEnvelope(named name: String?, in envelopes: [Envelope]) -> Envelope? {
        guard let name else { return nil }
        let needle = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else { return nil }
        if let exact = envelopes.first(where: { $0.name.lowercased() == needle }) {
            return exact
        }
        return envelopes.first { envelope in
            let hay = envelope.name.lowercased()
            return hay.contains(needle) || needle.contains(hay)
        }
    }
}
