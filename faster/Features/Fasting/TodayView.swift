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
                VStack(spacing: Spacing.lg) {
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
                        RatingRow(label: "Mood", icon: "face.smiling", value: $mood, tint: AppColor.accent)
                        RatingRow(label: "Energy", icon: "bolt.fill", value: $energy, tint: .orange)
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
    }

    private func save() {
        session.moodAtBreakFast = mood
        session.energyAtBreakFast = energy
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
