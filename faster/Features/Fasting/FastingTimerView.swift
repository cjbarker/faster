import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

struct FastingTimerView: View {
    var session: FastSession
    @State private var now: Date = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsed: TimeInterval  { now.timeIntervalSince(session.actualStart) }
    private var target:  TimeInterval  { session.targetDurationSeconds }
    private var progress: Double       { target > 0 ? min(1.0, elapsed / target) : 0 }
    private var phase: FastingPhase    { FastingPhase.phase(forHoursElapsed: elapsed / 3600) }
    private var isComplete: Bool       { progress >= 1.0 }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill((isComplete ? AppColor.accent : AppColor.fastingRing).opacity(0.06))
                    .frame(width: 296, height: 296)

                RingProgress(
                    progress: progress,
                    tint: isComplete ? AppColor.accent : AppColor.fastingRing,
                    lineWidth: 20,
                    showGlow: true
                )
                .frame(width: 264, height: 264)

                VStack(spacing: 6) {
                    Image(systemName: phase.symbolName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(phase.phaseColor)
                        .symbolRenderingMode(.hierarchical)

                    Text(formatHMS(elapsed))
                        .font(AppFont.timer)
                        .contentTransition(.numericText())
                        .foregroundStyle(.primary)

                    Text("of \(formatHMS(target))")
                        .font(AppFont.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            // Phase label pill
            Label {
                Text(isComplete ? "Goal reached!" : phase.title)
                    .font(AppFont.callout)
            } icon: {
                Image(systemName: isComplete ? "checkmark.circle.fill" : phase.symbolName)
                    .symbolRenderingMode(.hierarchical)
            }
            .foregroundStyle(isComplete ? AppColor.accent : Color.secondary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, 6)
            .background(
                (isComplete ? AppColor.accent : AppColor.fastingRing).opacity(0.10),
                in: Capsule()
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: phase)

            // Phase tagline
            Text(phase.tagline)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onReceive(tick) { now = $0 }
        .onChange(of: phase) { _, newPhase in
            Task { await pushLiveActivityUpdate(to: newPhase) }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.title) — \(Int(progress * 100)) percent complete")
    }

    private func formatHMS(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func pushLiveActivityUpdate(to phase: FastingPhase) async {
        #if canImport(ActivityKit)
        let state = FastingActivityAttributes.ContentState(
            start: session.actualStart,
            end:   session.plannedEnd,
            phaseTitle: phase.title
        )
        let content = ActivityContent(state: state, staleDate: session.plannedEnd)
        for activity in Activity<FastingActivityAttributes>.activities {
            await activity.update(content)
        }
        #endif
    }
}
