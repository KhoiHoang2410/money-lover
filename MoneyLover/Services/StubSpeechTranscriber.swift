import Foundation

/// A microphone-free `SpeechTranscribing` for the simulator and previews. It "hears" a fixed
/// Vietnamese phrase so the parse → review → save flow can be exercised without hardware.
/// The live path uses `LiveSpeechTranscriber` on device.
final class StubSpeechTranscriber: SpeechTranscribing, @unchecked Sendable {
    private let phrase: String
    private var continuation: AsyncThrowingStream<String, any Error>.Continuation?

    init(phrase: String = "bánh mì 40k cho 2 người") {
        self.phrase = phrase
    }

    var localeIdentifier: String { get async { "vi-VN" } }

    func prepare() async throws {}

    func start() async throws -> AsyncThrowingStream<String, any Error> {
        AsyncThrowingStream { continuation in
            self.continuation = continuation
            continuation.yield(phrase)
        }
    }

    func stop() async {
        continuation?.finish()
        continuation = nil
    }
}
