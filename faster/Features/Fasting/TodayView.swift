import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @Query private var profiles: [UserProfile]
    @Query private var plans: [FastingPlan]
    @Query private var goals: [Goal]
    @Query(sort: \FastSession.actualStart, order: .reverse) private var sessions: [FastSession]
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]

    @State private var guidance: GuidanceContent?
    @State private var showEndConfirm = false
    @State private var showAdjustSheet = false
    @State private var moodTarget: FastSession?
    @State private var fastingError: FastingError?

    private var activeSession: FastSession? { sessions.first { $0.isActive } }
    private var plan: FastingPlan? { plans.first }
    private var profile: UserProfile? { profiles.first }

    private var energyData: EnergyData? {
        guard let p = profile, let w = weights.first, let g = goals.first else { return nil }
        let bmr    = EnergyMath.bmr(sex: p.sex, weightKg: w.weightKg, heightCm: p.heightCm, ageYears: p.ageYears)
        let tdee   = EnergyMath.tdee(bmr: bmr, activity: p.activityLevel)
        let target = EnergyMath.targetDailyCalories(tdee: tdee, sex: p.sex, currentWeightKg: w.weightKg)
        let days   = EnergyMath.projectedDaysToGoal(currentWeightKg: w.weightKg,
                                                     targetWeightKg: g.targetWeightKg,
                                                     dailyDeficit: target.deficit)
        return EnergyData(targetCalories: target.calories, deficit: target.deficit, projectedDays: days)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Medical advisory — shown whenever onboarding safety flags are set
                    if let flags = profile?.medicalFlags, !flags.isEmpty {
                        MedicalFlagsBanner(flags: flags)
                            .padding(.horizontal)
                            .padding(.top, Spacing.xs)
                    }

                    if let session = activeSession {
                        FastingTimerView(session: session)
                            .padding(.top, Spacing.sm)

                        actionBar

                        if let guidance {
                            GuidanceSection(guidance: guidance, session: session)
                        }
                    } else {
                        NotFastingCard(plan: plan) { start() }
                            .padding(.top, Spacing.md)
                    }

                    // Energy budget — shows daily calorie target and projected goal
                    if let data = energyData {
                        EnergyBudgetCard(data: data)
                            .padding(.horizontal)
                    }

                    if let guidance {
                        NavigationLink {
                            AllowedConsumablesView(items: guidance.allowed)
                        } label: {
                            AllowedPreviewRow(items: guidance.allowed)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    FooterDisclaimer()
                }
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Today")
            .task { loadGuidance() }
            .confirmationDialog("End fast now?", isPresented: $showEndConfirm) {
                Button("End early", role: .destructive) { endFast(reason: .endedEarly) }
                Button("I reached my goal")             { endFast(reason: .completed) }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showAdjustSheet) {
                if let session = activeSession {
                    AdjustStartSheet(session: session)
                }
            }
            .sheet(item: $moodTarget) { session in
                MoodEnergySheet(session: session)
            }
            .alert(
                "Can't Start Fast",
                isPresented: Binding(get: { fastingError != nil }, set: { if !$0 { fastingError = nil } })
            ) {
                Button("OK", role: .cancel) { fastingError = nil }
            } message: {
                Text(fastingError?.errorDescription ?? "")
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder private var actionBar: some View {
        HStack(spacing: Spacing.sm) {
            Button {
                showAdjustSheet = true
            } label: {
                Label("Adjust Start", systemImage: "clock.arrow.circlepath")
                    .font(AppFont.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .controlSize(.large)

            Button(role: .destructive) {
                showEndConfirm = true
            } label: {
                Label("End Fast", systemImage: "stop.circle.fill")
                    .font(AppFont.callout)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.destructive)
            .controlSize(.large)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func loadGuidance() {
        do { guidance = try deps.guidanceProvider.load() } catch {
            guidance = GuidanceContent(cards: [], allowed: [])
        }
    }

    private func start() {
        guard let plan else { return }
        let controller = FastingController(context: context, scheduler: deps.notificationScheduler, healthStore: deps.healthStore)
        do {
            _ = try controller.startFast(plan: plan)
        } catch let error as FastingError {
            fastingError = error
        } catch {}
    }

    private func endFast(reason: FastEndReason) {
        guard let session = activeSession else { return }
        let controller = FastingController(context: context, scheduler: deps.notificationScheduler, healthStore: deps.healthStore)
        Task {
            try? await controller.endFast(session, reason: reason, writeToHealthKit: profile?.writeFastsToHealthKit ?? false)
            await MainActor.run { moodTarget = session }
        }
    }
}

// MARK: - Not Fasting Card

private struct NotFastingCard: View {
    var plan: FastingPlan?
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(AppColor.eatingRing.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColor.eatingGradient)
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.top, Spacing.sm)

            VStack(spacing: Spacing.xs) {
                Text("Eating Window")
                    .font(AppFont.title3)
                Text("Finish your last meal, then start your \(plan?.protocolKind.rawValue ?? "16:8") fast.")
                    .font(AppFont.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onStart()
            } label: {
                Label("Start \(plan?.protocolKind.rawValue ?? "16:8") Fast", systemImage: "play.fill")
                    .font(AppFont.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.xs)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColor.accent)
            .controlSize(.large)
            .padding(.bottom, Spacing.xs)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.lg, style: .continuous))
        .padding(.horizontal)
    }
}

// MARK: - Guidance Section

private struct GuidanceSection: View {
    var guidance: GuidanceContent
    var session: FastSession

    var body: some View {
        let ctx = GuidanceContext(
            phase: FastingPhase.phase(forHoursElapsed: session.durationSeconds / 3600),
            hoursElapsed: session.durationSeconds / 3600,
            isFasting: session.isActive,
            minutesUntilBreakFast: Int((session.plannedEnd.timeIntervalSinceNow) / 60)
        )
        let resolver = GuidanceResolver(content: guidance)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            if let current = resolver.current(for: ctx) {
                GuidanceCardView(card: current, isCurrent: true)
            }
            ForEach(resolver.upcoming(for: ctx)) { card in
                GuidanceCardView(card: card, isCurrent: false)
            }
        }
        .padding(.horizontal)
    }
}

private struct GuidanceCardView: View {
    var card: GuidanceCard
    var isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(card.title)
                    .font(AppFont.headline)
                Spacer()
                if isCurrent {
                    Label("Now", systemImage: "clock.fill")
                        .font(AppFont.caption2)
                        .foregroundStyle(AppColor.fastingRing)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 3)
                        .background(AppColor.fastingRing.opacity(0.12), in: Capsule())
                } else if let h = card.hourMin {
                    Text("h\(h)+")
                        .font(AppFont.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Text(card.body)
                .font(AppFont.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isCurrent ? AppColor.fastingRing.opacity(0.07) : AppColor.secondaryBackground,
            in: RoundedRectangle(cornerRadius: CR.md, style: .continuous)
        )
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: CR.md, style: .continuous)
                    .strokeBorder(AppColor.fastingRing.opacity(0.22), lineWidth: 1)
            }
        }
    }
}

// MARK: - Allowed Preview Row

private struct AllowedPreviewRow: View {
    var items: [AllowedConsumable]

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 22))
                .foregroundStyle(AppColor.accentGradient)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("What's allowed while fasting")
                    .font(AppFont.headline)
                Text("Water, black coffee, plain tea and more — tap to see details.")
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.md)
        .background(AppColor.secondaryBackground,
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
    }
}

// MARK: - Footer

private struct FooterDisclaimer: View {
    var body: some View {
        Text("Not medical advice. Not a treatment for any condition.")
            .font(AppFont.caption)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

// MARK: - Adjust Start Sheet

private struct AdjustStartSheet: View {
    var session: FastSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @State private var newStart: Date

    init(session: FastSession) {
        self.session = session
        _newStart = State(initialValue: session.actualStart)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Actual start",
                        selection: $newStart,
                        in: (Date().addingTimeInterval(-48 * 3600))...Date(),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } footer: {
                    Text("You can adjust up to 48 hours back.")
                        .font(AppFont.caption)
                }
            }
            .navigationTitle("Adjust start time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
        }
    }

    private func save() {
        let controller = FastingController(context: context, scheduler: deps.notificationScheduler, healthStore: deps.healthStore)
        try? controller.adjustStart(session, to: newStart)
    }
}

// MARK: - Mood & Energy Sheet

private struct MoodEnergySheet: View {
    var session: FastSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var mood: Int = 3
    @State private var energy: Int = 3
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColor.accentGradient)
                            .symbolRenderingMode(.hierarchical)
                        Text("How do you feel?")
                            .font(AppFont.title)
                        Text("Rate your mood and energy after breaking your fast.")
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.lg)

                    VStack(spacing: Spacing.md) {
                        RatingRow(label: "Mood",   icon: "face.smiling", value: $mood,   tint: AppColor.accent)
                        RatingRow(label: "Energy", icon: "bolt.fill",    value: $energy, tint: .orange)

                        // Session notes
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Notes", systemImage: "note.text")
                                .font(AppFont.headline)
                                .symbolRenderingMode(.hierarchical)
                            TextField("How did this fast go? (optional)", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                                .font(AppFont.callout)
                        }
                        .cardStyle()
                    }
                    .padding(.horizontal)

                    VStack(spacing: Spacing.sm) {
                        Button("Save") { save(); dismiss() }
                            .buttonStyle(.borderedProminent)
                            .tint(AppColor.accent)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)

                        Button("Skip") { dismiss() }
                            .font(AppFont.callout)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, Spacing.xl)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            mood   = session.moodAtBreakFast   ?? 3
            energy = session.energyAtBreakFast ?? 3
            notes  = session.notes
        }
    }

    private func save() {
        session.moodAtBreakFast   = mood
        session.energyAtBreakFast = energy
        session.notes             = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
    }
}

private struct RatingRow: View {
    var label: String
    var icon: String
    @Binding var value: Int
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(label, systemImage: icon)
                .font(AppFont.headline)
                .symbolRenderingMode(.hierarchical)

            HStack(spacing: Spacing.sm) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { value = i }
                    } label: {
                        Circle()
                            .fill(i <= value ? tint : tint.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(i))
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(i <= value ? .white : tint.opacity(0.5))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Medical Flags Banner

private struct MedicalFlagsBanner: View {
    var flags: [String]

    private var advisoryLines: [String] {
        var lines: [String] = []
        if flags.contains("insulin_or_sulfonylureas") {
            lines.append("You take insulin or sulfonylureas — monitor blood sugar closely during fasts.")
        }
        if flags.contains("bp_meds") {
            lines.append("You take blood pressure medication — watch for symptoms and consult your doctor before extending fasts.")
        }
        if flags.contains("meds_with_food") {
            lines.append("You take medications that require food — plan doses within your eating window.")
        }
        return lines
    }

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Medical advisory")
                    .font(AppFont.callout)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                ForEach(advisoryLines, id: \.self) { line in
                    Text(line)
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: CR.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: CR.md, style: .continuous)
                .strokeBorder(.orange.opacity(0.22), lineWidth: 1)
        }
    }
}

// MARK: - Energy Budget Card

private struct EnergyData {
    let targetCalories: Double
    let deficit: Double
    let projectedDays: Int?
}

private struct EnergyBudgetCard: View {
    var data: EnergyData

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Energy Budget", systemImage: "bolt.heart.fill")
                .font(AppFont.headline)
                .foregroundStyle(AppColor.accentGradient)
                .symbolRenderingMode(.hierarchical)

            HStack(spacing: 0) {
                statColumn(
                    value: "\(Int(data.targetCalories.rounded()))",
                    unit: "kcal",
                    label: "Daily target"
                )
                Divider()
                    .frame(height: 36)
                    .padding(.horizontal, Spacing.md)
                statColumn(
                    value: "\(Int(data.deficit.rounded()))",
                    unit: "kcal",
                    label: "Daily deficit"
                )
                if let days = data.projectedDays {
                    Divider()
                        .frame(height: 36)
                        .padding(.horizontal, Spacing.md)
                    statColumn(
                        value: "~\(days)",
                        unit: "days",
                        label: "To goal"
                    )
                }
            }
        }
        .cardStyle()
    }

    private func statColumn(value: String, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value)
                    .font(AppFont.title3)
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(AppFont.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(AppFont.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
