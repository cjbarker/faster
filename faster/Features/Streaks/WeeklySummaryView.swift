import SwiftUI
import SwiftData
import Charts

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

                    MoodEnergyTrendChart(sessions: sessions)

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

            VStack(alignment: .leading, spacing: 3) {
                Text(session.actualStart, style: .date)
                    .font(AppFont.callout)
                Text("\(session.protocolKind.rawValue) · \(Int(session.durationSeconds / 3600))h fasted")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
                if let reason = session.endReason {
                    Text(reason.displayTitle)
                        .font(AppFont.caption2)
                        .foregroundStyle(reason.badgeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(reason.badgeColor.opacity(0.10),
                                    in: Capsule())
                }
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

// MARK: - Mood & Energy Trend Chart

private struct MoodEnergyTrendChart: View {
    var sessions: [FastSession]

    private struct TrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let series: String
    }

    private var thirtyDaysAgo: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    }

    private var points: [TrendPoint] {
        let recent = sessions.filter { $0.actualStart >= thirtyDaysAgo && $0.actualEnd != nil }
        var result: [TrendPoint] = []
        for s in recent {
            let date = s.actualEnd ?? s.actualStart
            if let mood = s.moodAtBreakFast {
                result.append(TrendPoint(date: date, value: Double(mood),   series: "Mood"))
            }
            if let energy = s.energyAtBreakFast {
                result.append(TrendPoint(date: date, value: Double(energy), series: "Energy"))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    var body: some View {
        if !points.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Label("Mood & Energy — 30 days", systemImage: "waveform.path.ecg")
                    .font(AppFont.headline)
                    .symbolRenderingMode(.hierarchical)

                Chart(points) { p in
                    LineMark(
                        x: .value("Date", p.date),
                        y: .value("Rating", p.value)
                    )
                    .foregroundStyle(by: .value("Series", p.series))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", p.date),
                        y: .value("Rating", p.value)
                    )
                    .foregroundStyle(by: .value("Series", p.series))
                    .symbolSize(30)
                }
                .chartForegroundStyleScale(["Mood": Color.yellow, "Energy": Color.orange])
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) {
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                        AxisValueLabel()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(Color.secondary)
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                    }
                }
                .chartLegend(position: .top, alignment: .trailing)
                .frame(height: 160)
            }
            .cardStyle()
        }
    }
}
