import Testing
import Foundation
@testable import MoneyLover

@Suite struct ExpenseParserTests {
    /// A model whose output (or thrown error) is supplied by the test.
    private struct FakeModel: ExpenseParsing {
        var result: RawExpenseExtraction = .empty
        var error: (any Error)?
        func extract(from transcript: String) async throws -> RawExpenseExtraction {
            if let error { throw error }
            return result
        }
    }

    private struct ModelFailure: Error {}

    private func envelope(_ name: String) -> Envelope {
        Envelope(name: name, iconName: "tag", allocation: Money(minorUnits: 1_000_000, currency: .vnd))
    }

    private func parser(_ raw: RawExpenseExtraction = .empty, error: (any Error)? = nil) -> ExpenseParser {
        ExpenseParser(model: FakeModel(result: raw, error: error))
    }

    // MARK: maps raw → draft

    @Test func mapsAmountNoteAndMatchedEnvelope() async {
        let envelopes = [envelope("Food"), envelope("Transport")]
        let raw = RawExpenseExtraction(amount: 40_000, currencyCode: "VND", note: "bánh mì cho 2 người", envelopeName: "Food")
        let draft = await parser(raw).parse("bánh mì 40k cho 2 người", envelopes: envelopes)

        #expect(draft.amount == Money(minorUnits: 40_000, currency: .vnd))
        #expect(draft.note == "bánh mì cho 2 người")
        #expect(draft.envelopeID == envelopes[0].id)
    }

    // MARK: amount validation in Swift

    @Test func zeroAmountBecomesNil() async {
        let draft = await parser(RawExpenseExtraction(amount: 0)).parse("free sample", envelopes: [])
        #expect(draft.amount == nil)
    }

    @Test func negativeAmountBecomesNil() async {
        let draft = await parser(RawExpenseExtraction(amount: -10)).parse("weird", envelopes: [])
        #expect(draft.amount == nil)
    }

    @Test func nonFiniteAmountBecomesNil() async {
        for value in [Double.nan, .infinity, -.infinity] {
            let draft = await parser(RawExpenseExtraction(amount: value)).parse("x", envelopes: [])
            #expect(draft.amount == nil)
        }
    }

    @Test func usdAmountRoundsToCents() async {
        let raw = RawExpenseExtraction(amount: 1.5, currencyCode: "usd")
        let draft = await parser(raw).parse("coffee 1.5 dollars", envelopes: [])
        #expect(draft.amount == Money(minorUnits: 150, currency: .usd))
    }

    // MARK: safe draft on unparseable / failing input

    @Test func emptyExtractionKeepsTranscriptAsNote() async {
        let draft = await parser(.empty).parse("  mumble mumble  ", envelopes: [])
        #expect(draft.amount == nil)
        #expect(draft.envelopeID == nil)
        #expect(draft.note == "mumble mumble")
    }

    @Test func modelErrorYieldsSafeDraftFromTranscript() async {
        let draft = await parser(error: ModelFailure()).parse("bún bò 50k", envelopes: [])
        #expect(draft.amount == nil)
        #expect(draft.note == "bún bò 50k")
    }

    @Test func blankNoteFallsBackToTranscript() async {
        let raw = RawExpenseExtraction(amount: 30_000, note: "   ")
        let draft = await parser(raw).parse("cà phê 30k", envelopes: [])
        #expect(draft.note == "cà phê 30k")
    }

    // MARK: envelope name matching

    @Test func envelopeMatchesCaseInsensitively() async {
        let envelopes = [envelope("Transport"), envelope("Food")]
        let raw = RawExpenseExtraction(amount: 25_000, envelopeName: "transport")
        let draft = await parser(raw).parse("grab 25k", envelopes: envelopes)
        #expect(draft.envelopeID == envelopes[0].id)
    }

    @Test func envelopeMatchesBySubstring() async {
        let envelopes = [envelope("Eating out"), envelope("Transport")]
        let raw = RawExpenseExtraction(amount: 60_000, envelopeName: "eating")
        let draft = await parser(raw).parse("dinner 60k", envelopes: envelopes)
        #expect(draft.envelopeID == envelopes[0].id)
    }

    @Test func unknownEnvelopeLeavesNil() async {
        let envelopes = [envelope("Food")]
        let raw = RawExpenseExtraction(amount: 60_000, envelopeName: "Entertainment")
        let draft = await parser(raw).parse("movie 60k", envelopes: envelopes)
        #expect(draft.envelopeID == nil)
    }

    @Test func missingEnvelopeNameLeavesNil() async {
        let draft = await parser(RawExpenseExtraction(amount: 60_000)).parse("x 60k", envelopes: [envelope("Food")])
        #expect(draft.envelopeID == nil)
    }

    // MARK: currency mapping

    @Test func unknownCurrencyFallsBackToDefault() async {
        let raw = RawExpenseExtraction(amount: 100, currencyCode: "EUR")
        let draft = await parser(raw).parse("x", envelopes: [], defaultCurrency: .vnd)
        #expect(draft.amount?.currency == .vnd)
    }

    @Test func missingCurrencyUsesProvidedDefault() async {
        let raw = RawExpenseExtraction(amount: 5, currencyCode: nil)
        let draft = await parser(raw).parse("x", envelopes: [], defaultCurrency: .usd)
        #expect(draft.amount?.currency == .usd)
    }
}
