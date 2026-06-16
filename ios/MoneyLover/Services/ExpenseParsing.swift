import Foundation

/// Extracts the raw fields of an expense from a transcript. Implemented on-device by
/// `FoundationModelExpenseParser` (Apple Foundation Models); faked in tests.
///
/// The model only reads text into fields — it performs no arithmetic and makes no decision
/// about whether to save. Validation and persistence happen in Swift.
protocol ExpenseParsing: Sendable {
    func extract(from transcript: String) async throws -> RawExpenseExtraction
}
