import SwiftUI
import SwiftData

struct WaterLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @Query(sort: \WaterEntry.date, order: .reverse) private var entries: [WaterEntry]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var latestWeightKg: Double { weights.first?.weightKg ?? 75 }
    private var targetMl: Double { Hydration.dailyTargetMl(weightKg: latestWeightKg) }
    private var todayMl: Double {
        let start = Calendar.current.startOfDay(for: Date())
        return entries.filter { $0.date >= start }.map(\.volumeMl).reduce(0, +)
    }
    private var todayEntries: [WaterEntry] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Hero ring
                    WaterRingHero(
                        todayMl: todayMl,
                        targetMl: targetMl,
                        label: format(todayMl),
                        sublabel: "of \(format(targetMl))"
                    )
                    .padding(.top, Spacing.md)

                    // Quick-add buttons
                    QuickAddRow { ml in addWater(ml) }
                        .padding(.horizontal)

                    // Today's log
                    TodayWaterLog(entries: todayEntries, formatFn: { format($0) }, onDelete: deleteEntry)
                        .padding(.horizontal)
                }
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Water")
        }
    }

    private func deleteEntry(_ entry: WaterEntry) {
        context.delete(entry)
        try? context.save()
    }

    private func addWater(_ ml: Double) {
        let entry = WaterEntry(date: Date(), volumeMl: ml, source: .manual)
        context.insert(entry)
        try? context.save()
        Task { try? await deps.healthStore.saveWater(ml: ml) }
    }

    private func format(_ ml: Double) -> String {
        switch profile?.unitSystem ?? .imperial {
        case .metric:   return "\(Int(ml.rounded())) mL"
        case .imperial: return String(format: "%.0f oz", UnitConversion.mlToFlOz(ml))
        }
    }
}

// MARK: - Hero Ring

private struct WaterRingHero: View {
    var todayMl: Double
    var targetMl: Double
    var label: String
    var sublabel: String

    var body: some View {
        ZStack {
            Circle()
                .fill(AppColor.eatingRing.opacity(0.06))
                .frame(width: 260, height: 260)

            RingProgress(
                progress: todayMl / max(1, targetMl),
                tint: AppColor.eatingRing,
                lineWidth: 20,
                showGlow: true
            )
            .frame(width: 228, height: 228)

            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(AppColor.eatingRing)
                    .symbolRenderingMode(.hierarchical)

                Text(label)
                    .font(AppFont.timer)
                    .contentTransition(.numericText())

                Text(sublabel)
                    .font(AppFont.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Quick Add Row

private struct QuickAddRow: View {
    var onAdd: (Double) -> Void

    private let amounts: [(ml: Double, label: String)] = [
        (250,  "8 oz"),
        (500,  "16 oz"),
        (750,  "24 oz"),
        (1000, "32 oz"),
    ]

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(amounts, id: \.ml) { item in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { onAdd(item.ml) }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                        Text(item.label)
                            .font(AppFont.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .foregroundStyle(AppColor.eatingRing)
                    .background(AppColor.eatingRing.opacity(0.10),
                                in: RoundedRectangle(cornerRadius: CR.sm, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Today's Log

private struct TodayWaterLog: View {
    var entries: [WaterEntry]
    var formatFn: (Double) -> String
    var onDelete: (WaterEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Today")
                .font(AppFont.title3)

            if entries.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "drop")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("No entries yet — tap to log water.")
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(entries) { entry in
                        HStack {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(AppColor.eatingRing)
                                .symbolRenderingMode(.hierarchical)
                                .frame(width: 24)

                            Text(entry.date, style: .time)
                                .font(AppFont.callout)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(formatFn(entry.volumeMl))
                                .font(AppFont.callout)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, Spacing.xs)
                        .padding(.horizontal, Spacing.md)
                        .background(AppColor.secondaryBackground,
                                    in: RoundedRectangle(cornerRadius: CR.sm, style: .continuous))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}
