import SwiftUI

/// The idle/listening step of voice entry: a mic button, the live transcript, and a prompt.
/// Tapping the mic starts recording; tapping again stops and hands off to parsing.
struct VoiceRecordView: View {
    let store: VoiceEntryStore

    private var isRecording: Bool { store.phase == .recording }

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Text(isRecording ? "Listening…" : "Tap the mic and say your expense")
                .font(.headline)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)

            Button(action: toggle) {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 120, height: 120)
                    .background(isRecording ? AnyShapeStyle(Theme.Palette.bad) : AnyShapeStyle(Theme.heroGradient))
                    .clipShape(Circle())
            }
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")

            if !store.transcript.isEmpty {
                Text(store.transcript)
                    .font(.title3)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            if let error = store.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.bad)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Text("Example: “bánh mì 40k cho 2 người”")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
    }

    private func toggle() {
        if isRecording {
            Task { await store.stopRecording() }
        } else {
            store.startRecording()
        }
    }
}
