import Foundation
import Observation

/// View state for voice expense capture: records speech, parses it into a draft, and holds the
/// editable review fields until the user explicitly saves. Nothing is ever saved automatically.
@MainActor
@Observable
final class VoiceEntryStore {
    /// Where the flow is: before recording, while listening, while understanding, or reviewing.
    enum Phase: Equatable {
        case idle
        case recording
        case parsing
        case review
    }

    private(set) var phase: Phase = .idle
    private(set) var transcript = ""
    private(set) var sources: [Source] = []
    private(set) var envelopes: [Envelope] = []
    var errorMessage: String?
    /// Set when a transaction has been saved, so the screen can dismiss.
    private(set) var didSave = false

    // Editable review fields, prefilled from the parsed draft.
    var amountMajor: Decimal = 0
    var sourceID: UUID?
    var envelopeID: UUID?
    var note = ""

    private let transcriber: any SpeechTranscribing
    private let parser: ExpenseParser
    private let sourcesRepo: SourceRepository
    private let transactionsRepo: TransactionRepository
    private let envelopesRepo: EnvelopeRepository
    private var transactions: [Transaction] = []
    private var recordingTask: Task<Void, Never>?

    init(
        transcriber: any SpeechTranscribing,
        parser: ExpenseParser,
        sources: SourceRepository,
        transactions: TransactionRepository,
        envelopes: EnvelopeRepository
    ) {
        self.transcriber = transcriber
        self.parser = parser
        self.sourcesRepo = sources
        self.transactionsRepo = transactions
        self.envelopesRepo = envelopes
    }

    func load() {
        do {
            sources = try sourcesRepo.all()
            envelopes = try envelopesRepo.all()
            transactions = try transactionsRepo.all()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var selectedSource: Source? {
        sources.first { $0.id == sourceID }
    }

    var canSave: Bool {
        selectedSource != nil && amountMajor > 0
    }

    /// A live warning when the amount would outpace or overspend the chosen envelope.
    var nudge: Signal? {
        guard amountMajor > 0,
              let envelopeID,
              let envelope = envelopes.first(where: { $0.id == envelopeID })
        else { return nil }
        return SignalEngine.envelopeNudge(
            envelope: envelope,
            transactions: transactions,
            adding: Money(major: amountMajor, currency: .vnd),
            asOf: .now
        )
    }

    func startRecording() {
        errorMessage = nil
        transcript = ""
        phase = .recording
        recordingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await transcriber.prepare()
                let stream = try await transcriber.start()
                for try await text in stream {
                    transcript = text
                }
            } catch {
                errorMessage = error.localizedDescription
                phase = .idle
            }
        }
    }

    func stopRecording() async {
        await transcriber.stop()
        await recordingTask?.value
        recordingTask = nil
        guard phase == .recording else { return }
        await parse()
    }

    private func parse() async {
        phase = .parsing
        let draft = await parser.parse(transcript, envelopes: envelopes, defaultCurrency: .vnd)
        apply(draft)
        phase = .review
    }

    private func apply(_ draft: ExpenseDraft) {
        amountMajor = draft.amount?.amount ?? 0
        note = draft.note
        envelopeID = draft.envelopeID
        sourceID = sources.first?.id
    }

    /// Saves the reviewed expense as a real transaction. Charged in the source's currency,
    /// matching manual entry. Requires `canSave`.
    func save() {
        guard let source = selectedSource else { return }
        let transaction = Transaction(
            kind: .expense,
            amount: Money(major: amountMajor, currency: source.currency),
            sourceID: source.id,
            note: note,
            envelopeID: envelopeID
        )
        do {
            try transactionsRepo.add(transaction)
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Discards the current draft and returns to the start to record again.
    func reset() {
        phase = .idle
        transcript = ""
        amountMajor = 0
        sourceID = nil
        envelopeID = nil
        note = ""
        errorMessage = nil
    }
}
