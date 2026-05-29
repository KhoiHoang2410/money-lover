import Foundation

/// Drives on-device speech-to-text for voice expense capture. Implemented live by
/// `LiveSpeechTranscriber` (iOS 26 `SpeechAnalyzer`); a `StubSpeechTranscriber` stands in on
/// the simulator and in previews where there is no microphone or on-device model.
protocol SpeechTranscribing: Sendable {
    /// The BCP-47 identifier of the locale transcription will use (e.g. "vi-VN", "en-US").
    var localeIdentifier: String { get async }

    /// Requests microphone + speech permission and ensures the locale's on-device model is ready.
    /// Throws if permission is denied or no usable locale/model is available.
    func prepare() async throws

    /// Starts capturing audio and yields the cumulative transcript as it grows, until `stop()`.
    func start() async throws -> AsyncThrowingStream<String, any Error>

    /// Stops capture and finalizes the transcript, ending the `start()` stream.
    func stop() async
}

/// Failures surfaced by the voice pipeline.
enum SpeechTranscriptionError: LocalizedError {
    case permissionDenied
    case localeUnsupported
    case modelUnavailable
    case audioUnavailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied: "Microphone or speech access was denied. Enable it in Settings."
        case .localeUnsupported: "On-device speech isn't available for this language."
        case .modelUnavailable: "The speech model isn't ready yet. Try again in a moment."
        case .audioUnavailable: "Couldn't start the microphone."
        }
    }
}

/// Failures surfaced by the expense parser.
enum ExpenseParsingError: LocalizedError {
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .modelUnavailable: "On-device understanding isn't available on this device."
        }
    }
}
