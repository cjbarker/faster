import Foundation
@preconcurrency import SwiftData
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif

enum FastingError: Error, LocalizedError {
    case alreadyActive
    case noActive
    case cooldownNotMet
    case invalidAdjustment

    var errorDescription: String? {
        switch self {
        case .alreadyActive:       return "A fast is already in progress."
        case .noActive:            return "There is no active fast to modify."
        case .cooldownNotMet:      return "Please wait at least 1 hour after ending a fast before starting a new one."
        case .invalidAdjustment:   return "Start time must be in the past and no more than 48h ago."
        }
    }
}

@MainActor
final class FastingController {
    private let context: ModelContext
    private let scheduler: NotificationScheduler
    private let healthStore: HealthStore

    init(context: ModelContext, scheduler: NotificationScheduler, healthStore: HealthStore) {
        self.context = context
        self.scheduler = scheduler
        self.healthStore = healthStore
    }

    // MARK: - Queries

    func activeFast() -> FastSession? {
        let descriptor = FetchDescriptor<FastSession>(
            predicate: #Predicate { $0.actualEnd == nil },
            sortBy: [SortDescriptor(\.actualStart, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    func lastCompletedFast() -> FastSession? {
        let descriptor = FetchDescriptor<FastSession>(
            predicate: #Predicate { $0.actualEnd != nil },
            sortBy: [SortDescriptor(\.actualEnd, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    // MARK: - Fast lifecycle

    func startFast(plan: FastingPlan, at start: Date = Date()) throws -> FastSession {
        if activeFast() != nil { throw FastingError.alreadyActive }
        if let last = lastCompletedFast(),
           let ended = last.actualEnd,
           Date().timeIntervalSince(ended) < 3600 {
            throw FastingError.cooldownNotMet
        }
        let end = start.addingTimeInterval(TimeInterval(plan.protocolKind.fastingHours) * 3600)
        let session = FastSession(
            protocolKind: plan.protocolKind,
            plannedStart: start,
            plannedEnd: end,
            actualStart: start
        )
        context.insert(session)
        try context.save()

        writeSharedState(start: start, end: end, protocolKind: plan.protocolKind)

        Task {
            await scheduler.rebuild(
                for: .fasting(start: start, end: end),
                plan: PlanPrefs(
                    hydrationNudgesEnabled: plan.hydrationNudgesEnabled,
                    electrolyteRemindersEnabled: plan.electrolyteRemindersEnabled,
                    dailyWeighInEnabled: plan.dailyWeighInEnabled
                )
            )
            await startLiveActivity(session: session)
        }
        return session
    }

    func adjustStart(_ session: FastSession, to newStart: Date) throws {
        guard session.isActive else { throw FastingError.noActive }
        let now = Date()
        guard newStart <= now,
              now.timeIntervalSince(newStart) <= 48 * 3600 else {
            throw FastingError.invalidAdjustment
        }
        let newEnd = newStart.addingTimeInterval(TimeInterval(session.protocolKind.fastingHours) * 3600)
        session.actualStart = newStart
        session.plannedStart = newStart
        session.plannedEnd   = newEnd
        try context.save()

        writeSharedState(start: newStart, end: newEnd, protocolKind: session.protocolKind)
    }

    func endFast(_ session: FastSession, reason: FastEndReason = .completed, writeToHealthKit: Bool = false) async throws {
        guard session.isActive else { throw FastingError.noActive }
        let end = Date()
        session.actualEnd  = end
        session.endReason  = session.completionRatio >= 0.9 ? .completed : reason
        try context.save()

        clearSharedState()
        await scheduler.rebuild(for: .none, plan: PlanPrefs())
        await endLiveActivity()

        if writeToHealthKit {
            try? await healthStore.saveFastingAsMindfulSession(start: session.actualStart, end: end)
        }
    }

    func logMoodAndEnergy(_ session: FastSession, mood: Int, energy: Int) throws {
        session.moodAtBreakFast    = mood
        session.energyAtBreakFast  = energy
        try context.save()
    }

    // MARK: - App Group / Widget data

    private enum SharedKey {
        static let suite    = "group.com.faster.app"
        static let start    = "fastStart"
        static let end      = "fastEnd"
        static let protocol_ = "fastProtocol"
    }

    private func writeSharedState(start: Date, end: Date, protocolKind: ProtocolKind) {
        let defaults = UserDefaults(suiteName: SharedKey.suite)
        defaults?.set(start,                 forKey: SharedKey.start)
        defaults?.set(end,                   forKey: SharedKey.end)
        defaults?.set(protocolKind.rawValue, forKey: SharedKey.protocol_)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func clearSharedState() {
        let defaults = UserDefaults(suiteName: SharedKey.suite)
        defaults?.removeObject(forKey: SharedKey.start)
        defaults?.removeObject(forKey: SharedKey.end)
        defaults?.removeObject(forKey: SharedKey.protocol_)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Live Activity

    private func startLiveActivity(session: FastSession) async {
        #if canImport(ActivityKit)
        // End any stale activities from a previous fast
        for activity in Activity<FastingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        let attrs = FastingActivityAttributes(protocolLabel: session.protocolKind.rawValue)
        let state = FastingActivityAttributes.ContentState(
            start: session.actualStart,
            end:   session.plannedEnd,
            phaseTitle: FastingPhase.phase(forHoursElapsed: 0).title
        )
        _ = try? Activity.request(
            attributes: attrs,
            content: ActivityContent(state: state, staleDate: session.plannedEnd)
        )
        #endif
    }

    private func endLiveActivity() async {
        #if canImport(ActivityKit)
        for activity in Activity<FastingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        #endif
    }
}
