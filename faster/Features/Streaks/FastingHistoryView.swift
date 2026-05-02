import SwiftUI
import SwiftData

struct FastingHistoryView: View {
    @Query(sort: \FastSession.actualStart, order: .reverse) private var sessions: [FastSession]
    @Query private var profiles: [UserProfile]

    private var unit: UnitSystem { profiles.first?.unitSystem ?? .imperial }

    var body: some View {
        ScrollView {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Fasts Yet",
                    systemImage: "clock.badge.questionmark",
                    description: Text("Complete your first fast to see it here.")
                )
                .padding(.top, Spacing.xxl)
            } else {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(sessions) { session in
                        HistoryRow(session: session)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.md)
            }
        }
        .navigationTitle("All Fasts")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - History Row

private struct HistoryRow: View {
    var session: FastSession

    private var completionColor: Color {
        session.completionRatio >= 0.9 ? AppColor.accent : .orange
    }
    private var durationHours: Int { Int(session.durationSeconds / 3600) }
    private var durationMins:  Int { Int((session.durationSeconds.truncatingRemainder(dividingBy: 3600)) / 60) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // ── Top row: date + completion % ──────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.actualStart, format: .dateTime.weekday(.wide).month(.abbreviated).day())
                        .font(AppFont.callout)
                        .fontWeight(.semibold)
                    Text(session.actualStart, style: .time)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(session.completionRatio * 100))%")
                    .font(AppFont.headline)
                    .foregroundStyle(completionColor)
            }

            // ── Middle row: protocol · duration · end reason ──────────────
            HStack(spacing: Spacing.sm) {
                badge(session.protocolKind.rawValue, color: AppColor.fastingRing)

                Text("\(durationHours)h \(durationMins)m fasted")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)

                if let reason = session.endReason {
                    badge(reason.displayTitle, color: reason.badgeColor)
                }
            }

            // ── Mood / energy ──────────────────────────────────────────────
            if session.moodAtBreakFast != nil || session.energyAtBreakFast != nil {
                HStack(spacing: Spacing.md) {
                    if let mood = session.moodAtBreakFast {
                        Label("\(mood)/5", systemImage: "face.smiling")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let energy = session.energyAtBreakFast {
                        Label("\(energy)/5", systemImage: "bolt")
                            .font(AppFont.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .symbolRenderingMode(.hierarchical)
            }

            // ── Notes ──────────────────────────────────────────────────────
            if !session.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(session.notes)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.md)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(AppFont.caption2)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.10), in: Capsule())
    }
}
