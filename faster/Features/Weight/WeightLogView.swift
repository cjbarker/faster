import SwiftUI
import SwiftData

struct WeightLogView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]
    @Query private var profiles: [UserProfile]
    @Query private var goals: [Goal]

    @State private var showLogSheet = false

    private var points: [WeightPoint] {
        entries.map { WeightPoint(date: $0.date, weightKg: $0.weightKg) }.sorted { $0.date < $1.date }
    }
    private var profile: UserProfile? { profiles.first }
    private var goal: Goal? { goals.first }
    private var unit: UnitSystem { profile?.unitSystem ?? .imperial }

    var body: some View {
        NavigationStack {
            List {
                Section("Trend") {
                    let trend = WeightProjection.movingAverage(points)
                    let projection = WeightProjection.projection(
                        latest: trend.last,
                        target: goal?.targetWeightKg ?? 0,
                        goalDate: goal?.targetDate
                    )
                    WeightChartView(points: points, trend: trend, projection: projection)
                }
                Section("Entries") {
                    if entries.isEmpty {
                        Text("No entries yet.").foregroundStyle(.secondary)
                    }
                    ForEach(entries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.date, style: .date)
                                Text(entry.source == .healthKit ? "Apple Health" : "Manual")
                                    .font(AppFont.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(format(entry.weightKg))
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showLogSheet = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Sync with Health") { Task { await pullFromHealth() } }
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogWeightSheet(unit: unit) { kg in
                    let entry = WeightEntry(date: Date(), weightKg: kg, source: .manual)
                    context.insert(entry)
                    try? context.save()
                    Task { try? await deps.healthStore.saveWeight(kg: kg) }
                }
            }
        }
    }

    private func format(_ kg: Double) -> String {
        switch unit {
        case .metric:   return String(format: "%.1f kg", kg)
        case .imperial: return "\(Int(UnitConversion.kgToLb(kg).rounded())) lb"
        }
    }

    private func delete(_ offsets: IndexSet) {
        for i in offsets { context.delete(entries[i]) }
        try? context.save()
    }

    private func pullFromHealth() async {
        let history = await deps.healthStore.weightHistory()
        for (date, kg) in history {
            let entry = WeightEntry(date: date, weightKg: kg, source: .healthKit)
            context.insert(entry)
        }
        try? context.save()
    }
}

private struct LogWeightSheet: View {
    var unit: UnitSystem
    var onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var kg: Double = 75

    var body: some View {
        NavigationStack {
            Form {
                WeightField(label: "Weight", kg: $kg, unitSystem: unit)
                Section {
                    Button("Save") { onSave(kg); dismiss() }.buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Log weight")
        }
    }
}
