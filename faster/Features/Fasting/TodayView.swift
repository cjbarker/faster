import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps
    @Query private var profiles: [UserProfile]
    @Query private var plans: [FastingPlan]
    @Query(sort: \FastSession.actualStart, order: .reverse) private var sessions: [FastSession]

    @State private var guidance: GuidanceContent?
    @State private var showEndConfirm = false
    @State private var showAdjustSheet = false
    @State private var moodTarget: FastSession?

    private var activeSession: FastSession? { sessions.first { $0.isActive } }
    private var plan: FastingPlan? { plans.first }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let session = activeSession {
                        FastingTimerView(session: session)
                            .padding(.top, 16)
                        HStack {
                            Button("Adjust Start") { showAdjustSheet = true }
                            Spacer()
                            Button(role: .destructive) { showEndConfirm = true } label: {
                                Text("End Fast")
                            }
                        }
                        .padding(.horizontal)

                        if let guidance {
                            GuidanceSection(guidance: guidance, session: session)
                        }
                    } else {
                        NotFastingCard(plan: plan) { start(); }
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
                .padding(.bottom, 32)
            }
            .navigationTitle("Today")
            .task { loadGuidance() }
            .confirmationDialog("End fast now?", isPresented: $showEndConfirm) {
                Button("End early", role: .destructive) { endFast(reason: .endedEarly) }
                Button("I reached my goal") { endFast(reason: .completed) }
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
        }
    }

    private func loadGuidance() {
        do { guidance = try deps.guidanceProvider.load() } catch {
            guidance = GuidanceContent(cards: [], allowed: [])
        }
    }

    private func start() {
        guard let plan else { return }
        let controller = FastingController(context: context, scheduler: deps.notificationScheduler, healthStore: deps.healthStore)
        _ = try? controller.startFast(plan: plan)
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

private struct NotFastingCard: View {
    var plan: FastingPlan?
    var onStart: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColor.eatingRing)
            Text("You're in your eating window").font(AppFont.headline)
            Text("When you finish your last meal, start your fast below.")
                .font(AppFont.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Start \(plan?.protocolKind.rawValue ?? "16:8") fast now") { onStart() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppColor.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

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
        return VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.title).font(AppFont.headline)
                Spacer()
                if isCurrent {
                    Label("Now", systemImage: "clock")
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.accent)
                } else if let h = card.hourMin {
                    Text("at \(h)h")
                        .font(AppFont.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(card.body).font(AppFont.body).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct AllowedPreviewRow: View {
    var items: [AllowedConsumable]
    var body: some View {
        HStack {
            Image(systemName: "list.bullet.rectangle").foregroundStyle(AppColor.accent)
            VStack(alignment: .leading) {
                Text("What's allowed while fasting").font(AppFont.headline)
                Text("Water, black coffee, plain tea, and more — tap to see details.")
                    .font(AppFont.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(AppColor.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct FooterDisclaimer: View {
    var body: some View {
        Text("Not medical advice. Not a treatment for any condition.")
            .font(AppFont.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
}

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
                DatePicker(
                    "Actual start",
                    selection: $newStart,
                    in: (Date().addingTimeInterval(-48 * 3600))...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                Section {
                    Button("Save") { save(); dismiss() }.buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Adjust start time")
        }
    }

    private func save() {
        let controller = FastingController(context: context, scheduler: deps.notificationScheduler, healthStore: deps.healthStore)
        try? controller.adjustStart(session, to: newStart)
    }
}

private struct MoodEnergySheet: View {
    var session: FastSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var mood: Int = 3
    @State private var energy: Int = 3

    var body: some View {
        NavigationStack {
            Form {
                Section("Mood") {
                    Picker("", selection: $mood) {
                        ForEach(1...5, id: \.self) { Text(String($0)).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section("Energy") {
                    Picker("", selection: $energy) {
                        ForEach(1...5, id: \.self) { Text(String($0)).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Section {
                    Button("Save") { save(); dismiss() }.buttonStyle(.borderedProminent)
                    Button("Skip") { dismiss() }
                }
            }
            .navigationTitle("How do you feel?")
        }
    }

    private func save() {
        session.moodAtBreakFast = mood
        session.energyAtBreakFast = energy
        try? context.save()
    }
}
