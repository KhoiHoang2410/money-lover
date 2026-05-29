import Foundation
import Speech
@preconcurrency import AVFoundation

/// On-device speech-to-text using the iOS 26 `SpeechAnalyzer` / `SpeechTranscriber` pipeline.
/// Prefers Vietnamese and falls back to English when the Vietnamese model is unavailable.
///
/// Device-only: it needs the microphone and the downloadable on-device speech model, so it is
/// never exercised in the simulator (the factory substitutes `StubSpeechTranscriber` there).
final class LiveSpeechTranscriber: SpeechTranscribing, @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var recognizerTask: Task<Void, Never>?
    private var analyzerFormat: AVAudioFormat?
    private var resolvedLocale = Locale(identifier: "en-US")

    private static let preferred = [Locale(identifier: "vi-VN"), Locale(identifier: "en-US")]

    var localeIdentifier: String { get async { resolvedLocale.identifier } }

    func prepare() async throws {
        guard await Self.requestMicrophonePermission() else {
            throw SpeechTranscriptionError.permissionDenied
        }
        resolvedLocale = try await Self.firstSupportedLocale()
    }

    func start() async throws -> AsyncThrowingStream<String, any Error> {
        let transcriber = SpeechTranscriber(
            locale: resolvedLocale,
            transcriptionOptions: [],
            reportingOptions: [.volatileResults],
            attributeOptions: []
        )
        self.transcriber = transcriber

        try await Self.ensureModel(for: transcriber, locale: resolvedLocale)

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
            throw SpeechTranscriptionError.modelUnavailable
        }
        analyzerFormat = format

        let (inputSequence, continuation) = AsyncStream<AnalyzerInput>.makeStream()
        inputContinuation = continuation
        try await analyzer.start(inputSequence: inputSequence)
        try startAudioEngine(convertingTo: format)

        return AsyncThrowingStream { outer in
            self.recognizerTask = Task {
                var finalized = AttributedString()
                do {
                    for try await result in transcriber.results {
                        if result.isFinal {
                            finalized += result.text
                            outer.yield(String(finalized.characters))
                        } else {
                            outer.yield(String((finalized + result.text).characters))
                        }
                    }
                    outer.finish()
                } catch {
                    outer.finish(throwing: error)
                }
            }
        }
    }

    func stop() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        inputContinuation?.finish()
        inputContinuation = nil
        if let analyzer {
            try? await analyzer.finalizeAndFinishThroughEndOfInput()
        }
        recognizerTask?.cancel()
        recognizerTask = nil
        analyzer = nil
        transcriber = nil
    }

    // MARK: - Audio

    private func startAudioEngine(convertingTo format: AVAudioFormat) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let converter = AVAudioConverter(from: inputFormat, to: format)

        inputNode.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            guard let self, let continuation = self.inputContinuation else { return }
            let converted = converter.flatMap { Self.convert(buffer, with: $0, to: format) } ?? buffer
            continuation.yield(AnalyzerInput(buffer: converted))
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    /// Feeds exactly one input buffer, tracked by a reference type so no `var` is captured by
    /// the converter's input block (which would warn under strict concurrency).
    private final class OneShotInput: @unchecked Sendable {
        private var buffer: AVAudioPCMBuffer?
        init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }
        func next(_ status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
            if let buffer {
                self.buffer = nil
                status.pointee = .haveData
                return buffer
            }
            status.pointee = .noDataNow
            return nil
        }
    }

    private static func convert(
        _ buffer: AVAudioPCMBuffer,
        with converter: AVAudioConverter,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else { return nil }
        let input = OneShotInput(buffer)
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in input.next(status) }
        return error == nil ? output : nil
    }

    // MARK: - Permissions & model

    private static func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func firstSupportedLocale() async throws -> Locale {
        let supported = await SpeechTranscriber.supportedLocales
        for locale in preferred {
            if supported.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) {
                return locale
            }
        }
        throw SpeechTranscriptionError.localeUnsupported
    }

    private static func ensureModel(for transcriber: SpeechTranscriber, locale: Locale) async throws {
        let installed = await SpeechTranscriber.installedLocales
        let target = locale.identifier(.bcp47)
        if installed.contains(where: { $0.identifier(.bcp47) == target }) { return }
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
    }
}
