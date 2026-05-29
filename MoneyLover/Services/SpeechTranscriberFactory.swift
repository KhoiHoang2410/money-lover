import Foundation

/// Picks the speech transcriber for the current environment: the on-device
/// `LiveSpeechTranscriber` on real hardware, and the microphone-free `StubSpeechTranscriber`
/// on the simulator (where there is no mic or on-device model).
enum SpeechTranscriberFactory {
    static func make() -> any SpeechTranscribing {
        #if targetEnvironment(simulator)
        StubSpeechTranscriber()
        #else
        LiveSpeechTranscriber()
        #endif
    }
}
