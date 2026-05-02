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
            ScrollView {
                VStack(spacing: Spacing.md) {
                    // Chart card
                    ChartCard(points: points, goal: goal)
                        .padding(.horizontal)

                    // Entries list
                    EntriesSection(entries: entries, format: format, onDelete: delete)
                        .padding(.horizontal)
                }
                .padding(.vertical, Spacing.md)
            }
            .navigationTitle("Weight")
            .task { await pullFromHealth() }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppColor.accent)
                    }
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
        guard !history.isEmpty else { return }

        // Build a set of already-stored HealthKit timestamps (rounded to the
        // nearest second) so re-running the sync never creates duplicates.
        let existing = Set(
            entries
                .filter { $0.source == .healthKit }
                .map { $0.date.timeIntervalSinceReferenceDate.rounded() }
        )

        var changed = false
        for (date, kg) in history {
            guard !existing.contains(date.timeIntervalSinceReferenceDate.rounded()) else { continue }
            context.insert(WeightEntry(date: date, weightKg: kg, source: .healthKit))
            changed = true
        }
        if changed { try? context.save() }
    }
}

// MARK: - Chart Card

private struct ChartCard: View {
    var points: [WeightPoint]
    var goal: Goal?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Trend", systemImage: "chart.line.uptrend.xyaxis")
                .font(AppFont.headline)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppColor.accentGradient)

            let trend = WeightProjection.movingAverage(points)
            let projection = WeightProjection.projection(
                latest: trend.last,
                target: goal?.targetWeightKg ?? 0,
                goalDate: goal?.targetDate
            )

            if points.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("Log your first weight to see a trend.")
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.xl)
                    Spacer()
                }
            } else {
                WeightChartView(points: points, trend: trend, projection: projection)
            }
        }
        .cardStyle()
    }
}

// MARK: - Entries Section

private struct EntriesSection: View {
    var entries: [WeightEntry]
    var format: (Double) -> String
    var onDelete: (IndexSet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Entries")
                .font(AppFont.title3)

            if entries.isEmpty {
                HStack {
                    Spacer()
                    Text("No entries yet.")
                        .font(AppFont.callout)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.lg)
                    Spacer()
                }
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(entries) { entry in
                        WeightEntryRow(entry: entry, formatted: format(entry.weightKg))
                    }
                    .onDelete(perform: onDelete)
                }
            }
        }
    }
}

private struct WeightEntryRow: View {
    var entry: WeightEntry
    var formatted: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: entry.source == .healthKit ? "heart.fill" : "pencil.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(entry.source == .healthKit ? Color.red : AppColor.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, style: .date)
                    .font(AppFont.callout)
                Text(entry.source == .healthKit ? "Apple Health" : "Manual")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formatted)
                .font(AppFont.headline)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.md)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.sm, style: .continuous))
    }
}

// MARK: - Log Weight Sheet

private struct LogWeightSheet: View {
    var unit: UnitSystem
    var onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var kg: Double = 75

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WeightField(label: "Weight", kg: $kg, unitSystem: unit)
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(kg); dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }
}
