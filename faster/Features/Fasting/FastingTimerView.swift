import SwiftUI

struct FastingTimerView: View {
    var session: FastSession
    @State private var now: Date = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsed: TimeInterval {
        now.timeIntervalSince(session.actualStart)
    }
    private var target: TimeInterval { session.targetDurationSeconds }
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, elapsed / target)
    }
    private var phase: FastingPhase {
        FastingPhase.phase(forHoursElapsed: elapsed / 3600)
    }

    var body: some View {
        ZStack {
            RingProgress(progress: progress, tint: AppColor.fastingRing, lineWidth: 18)
                .frame(width: 240, height: 240)
            VStack(spacing: 6) {
                Text(phase.title)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                Text(format(elapsed: elapsed))
                    .font(AppFont.timer)
                    .contentTransition(.numericText())
                Text("of \(format(elapsed: target))")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onReceive(tick) { now = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(phase.title) — \(Int(progress * 100)) percent complete")
    }

    private func format(elapsed seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
