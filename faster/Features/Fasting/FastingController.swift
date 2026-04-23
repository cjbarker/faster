import Foundation
import SwiftData

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
        Task {
            await scheduler.rebuild(
                for: .fasting(start: start, end: end),
                plan: PlanPrefs(
                    hydrationNudgesEnabled: plan.hydrationNudgesEnabled,
                    electrolyteRemindersEnabled: plan.electrolyteRemindersEnabled,
                    dailyWeighInEnabled: plan.dailyWeighInEnabled
                )
            )
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
        session.actualStart = newStart
        session.plannedStart = newStart
        session.plannedEnd = newStart.addingTimeInterval(TimeInterval(session.protocolKind.fastingHours) * 3600)
        try context.save()
    }

    func endFast(_ session: FastSession, reason: FastEndReason = .completed, writeToHealthKit: Bool = false) async throws {
        guard session.isActive else { throw FastingError.noActive }
        let end = Date()
        session.actualEnd = end
        session.endReason = session.completionRatio >= 0.9 ? .completed : reason
        try context.save()
        await scheduler.rebuild(for: .none, plan: PlanPrefs())
        if writeToHealthKit {
            try? await healthStore.saveFastingAsMindfulSession(start: session.actualStart, end: end)
        }
    }

    func logMoodAndEnergy(_ session: FastSession, mood: Int, energy: Int) throws {
        session.moodAtBreakFast = mood
        session.energyAtBreakFast = energy
        try context.save()
    }
}
