import SwiftUI
import SwiftData

struct WeeklySummaryView: View {
    @Query(sort: \FastSession.actualStart, order: .reverse) private var sessions: [FastSession]

    private var snapshots: [FastSessionSnapshot] {
        sessions.map {
            FastSessionSnapshot(
                startedAt: $0.actualStart,
                endedAt: $0.actualEnd,
                completionRatio: $0.completionRatio,
                durationSeconds: $0.durationSeconds,
                mood: $0.moodAtBreakFast,
                energy: $0.energyAtBreakFast
            )
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("This week") {
                    let summary = StreakService.weeklySummary(from: snapshots)
                    row("Completed fasts", "\(summary.completedCount)")
                    row("Total fasting hours", String(format: "%.1f", summary.totalFastingHours))
                    if let mood = summary.avgMood { row("Avg mood", String(format: "%.1f / 5", mood)) }
                    if let energy = summary.avgEnergy { row("Avg energy", String(format: "%.1f / 5", energy)) }
                }
                Section("Streak") {
                    let streak = StreakService.currentStreak(from: snapshots)
                    HStack {
                        Image(systemName: "flame.fill").foregroundStyle(.orange)
                        Text("\(streak) day\(streak == 1 ? "" : "s")")
                            .font(AppFont.headline)
                    }
                    Text("A fast counts when you reach ≥ 90% of its planned duration.")
                        .font(AppFont.caption).foregroundStyle(.secondary)
                }
                Section("Recent fasts") {
                    ForEach(sessions.prefix(10)) { s in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(s.actualStart, style: .date)
                                Text("\(s.protocolKind.rawValue) — \(Int(s.durationSeconds/3600))h")
                                    .font(AppFont.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(s.completionRatio * 100))%")
                                .foregroundStyle(s.completionRatio >= 0.9 ? AppColor.accent : .orange)
                        }
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}
