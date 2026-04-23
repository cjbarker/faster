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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        RingProgress(progress: todayMl / max(1, targetMl),
                                     tint: AppColor.eatingRing,
                                     lineWidth: 18)
                            .frame(width: 220, height: 220)
                        VStack {
                            Text(format(todayMl))
                                .font(AppFont.timer)
                            Text("of \(format(targetMl))")
                                .font(AppFont.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 20)

                    HStack(spacing: 12) {
                        quickAdd(250, "+8 oz")
                        quickAdd(500, "+16 oz")
                        quickAdd(1000, "+32 oz")
                    }
                    .padding(.horizontal)

                    List {
                        Section("Today's logs") {
                            ForEach(entries.filter { Calendar.current.isDateInToday($0.date) }) { entry in
                                HStack {
                                    Text(entry.date, style: .time)
                                    Spacer()
                                    Text(format(entry.volumeMl))
                                }
                            }
                        }
                    }
                    .frame(minHeight: 200)
                }
            }
            .navigationTitle("Water")
        }
    }

    @ViewBuilder private func quickAdd(_ ml: Double, _ label: String) -> some View {
        Button(label) {
            let entry = WaterEntry(date: Date(), volumeMl: ml, source: .manual)
            context.insert(entry)
            try? context.save()
            Task { try? await deps.healthStore.saveWater(ml: ml) }
        }
        .buttonStyle(.borderedProminent)
        .tint(AppColor.eatingRing)
        .frame(maxWidth: .infinity)
    }

    private func format(_ ml: Double) -> String {
        switch profile?.unitSystem ?? .imperial {
        case .metric:   return "\(Int(ml.rounded())) mL"
        case .imperial: return String(format: "%.0f oz", UnitConversion.mlToFlOz(ml))
        }
    }
}
