import SwiftUI

/// A circular progress ring for a goal, with its ahead/behind percentage.
struct GoalRing: View {
    let goal: Goal
    let progress: GoalProgress

    @Environment(\.reduceMotionPreference) private var reduceMotionPreference
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @State private var revealed = false

    private var reduceMotion: Bool { reduceMotionPreference || systemReduceMotion }

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle().stroke(Theme.Palette.pinkSoft, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: revealed ? progress.fractionOfTarget : 0)
                    .stroke(Theme.heroGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(progress.fractionOfTarget, format: .percent.precision(.fractionLength(0)))
                    .font(.headline)
            }
            .frame(width: 80, height: 80)

            Text(goal.name).bold()
            Label {
                Text(abs(progress.pct), format: .percent.precision(.fractionLength(1)))
            } icon: {
                Image(systemName: progress.pct >= 0 ? "arrow.up" : "arrow.down")
            }
            .font(.caption).bold()
            .foregroundStyle(progress.pct >= 0 ? Theme.Palette.ok : Theme.Palette.bad)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(.background, in: .rect(cornerRadius: Theme.Radius.tile))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.tile).strokeBorder(Theme.Palette.line)
        }
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(Theme.Motion.reveal) { revealed = true }
            }
        }
    }
}
