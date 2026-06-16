import Foundation
import FoundationModels

/// On-device expense extraction via Apple Foundation Models. The model only fills text fields;
/// it does no arithmetic and never decides whether to save — that is enforced in Swift.
///
/// Runs entirely on-device, so it needs a real iPhone with Apple Intelligence enabled; on the
/// simulator the model may report unavailable and `extract` throws, which the caller treats as
/// an empty draft.
struct FoundationModelExpenseParser: ExpenseParsing {
    /// Fields the model reads out of a spoken phrase. Non-optional with empty sentinels so the
    /// guided-generation schema stays simple; sentinels are normalised away below.
    @Generable
    struct ExpenseExtraction {
        @Guide(description: "The amount as a plain number in the currency's main unit. Expand spoken shorthand like '40k' to 40000 and '2 triệu' to 2000000. Use 0 when no amount is said. Do no other arithmetic — never divide by the number of people.")
        var amount: Double

        @Guide(description: "Three-letter ISO currency code such as VND or USD. Use VND when no currency is mentioned.")
        var currencyCode: String

        @Guide(description: "A short note describing what was bought, in the language spoken. Keep details like how many people, e.g. 'bánh mì cho 2 người'.")
        var note: String

        @Guide(description: "A single spending-category guess such as Food, Transport, or Coffee. Leave empty when unsure.")
        var envelopeName: String
    }

    func extract(from transcript: String) async throws -> RawExpenseExtraction {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw ExpenseParsingError.modelUnavailable
        }
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        let response = try await session.respond(to: transcript, generating: ExpenseExtraction.self)
        return Self.normalize(response.content)
    }

    private static let instructions = """
    You extract structured details from a short spoken sentence describing a single expense.
    The sentence may be in Vietnamese or English. Fill the fields exactly as instructed and \
    do not perform any calculation beyond expanding spoken number shorthand. If the sentence \
    is not about spending money, return 0 for the amount.
    """

    /// Empty/zero sentinels → nil so the pure parser can validate and fall back cleanly.
    private static func normalize(_ content: ExpenseExtraction) -> RawExpenseExtraction {
        func cleaned(_ string: String) -> String? {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        return RawExpenseExtraction(
            amount: content.amount > 0 ? content.amount : nil,
            currencyCode: cleaned(content.currencyCode),
            note: cleaned(content.note),
            envelopeName: cleaned(content.envelopeName)
        )
    }
}
