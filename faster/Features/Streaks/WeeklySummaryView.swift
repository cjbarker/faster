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
    private var summary: WeeklySummary { StreakService.weeklySummary(from: snapshots) }
    private var streak: Int { StreakService.currentStreak(from: snapshots) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    StreakHeroCard(streak: streak)

                    StatsGrid(summary: summary)

                    RecentFastsList(sessions: Array(sessions.prefix(10)))
                }
                .padding(.horizontal)
                .padding(.vertical, Spacing.md)
            }
            .navigationTitle("Summary")
        }
    }
}

// MARK: - Streak Hero Card

private struct StreakHeroCard: View {
    var streak: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.14))
                    .frame(width: 64, height: 64)
                Image(systemName: streak > 0 ? "flame.fill" : "flame")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(streak > 0 ? Color.orange : Color.secondary)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(AppFont.largeTitle)
                        .foregroundStyle(.primary)
                    Text("day\(streak == 1 ? "" : "s")")
                        .font(AppFont.title3)
                        .foregroundStyle(.secondary)
                }
                Text("current streak")
                    .font(AppFont.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if streak >= 7 {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.yellow)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .cardStyle()
    }
}

// MARK: - Stats Grid

private struct StatsGrid: View {
    var summary: WeeklySummary

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
            StatCard(
                icon: "checkmark.seal.fill",
                value: "\(summary.completedCount)",
                label: "Fasts this week",
                tint: AppColor.accent
            )
            StatCard(
                icon: "clock.fill",
                value: String(format: "%.1f", summary.totalFastingHours),
                label: "Hours fasted",
                tint: AppColor.fastingRing
            )
            if let mood = summary.avgMood {
                StatCard(
                    icon: "face.smiling.fill",
                    value: String(format: "%.1f / 5", mood),
                    label: "Avg mood",
                    tint: .yellow
                )
            }
            if let energy = summary.avgEnergy {
                StatCard(
                    icon: "bolt.fill",
                    value: String(format: "%.1f / 5", energy),
                    label: "Avg energy",
                    tint: .orange
                )
            }
        }
    }
}

private struct StatCard: View {
    var icon: String
    var value: String
    var label: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(AppFont.title)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Recent Fasts

private struct RecentFastsList: View {
    var sessions: [FastSession]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Recent Fasts")
                .font(AppFont.title3)
                .padding(.top, Spacing.xs)

            if sessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        Text("No fasts recorded yet.")
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.xl)
                    Spacer()
                }
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(sessions) { s in
                        RecentFastRow(session: s)
                    }
                }
            }

            Text("A fast counts when you reach ≥ 90% of its planned duration.")
                .font(AppFont.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, Spacing.xs)
        }
    }
}

private struct RecentFastRow: View {
    var session: FastSession

    private var completionColor: Color {
        session.completionRatio >= 0.9 ? AppColor.accent : .orange
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(completionColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: session.completionRatio >= 0.9 ? "checkmark" : "minus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(completionColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.actualStart, style: .date)
                    .font(AppFont.callout)
                Text("\(session.protocolKind.rawValue) · \(Int(session.durationSeconds / 3600))h fasted")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(session.completionRatio * 100))%")
                .font(AppFont.headline)
                .foregroundStyle(completionColor)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
    }
}
