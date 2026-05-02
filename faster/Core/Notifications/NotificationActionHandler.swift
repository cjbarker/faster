import Foundation
import UserNotifications
import SwiftData

/// Handles notification action button taps (Log Water / End Fast / Start Fast).
/// Registered as UNUserNotificationCenter.current().delegate in AppDependencies.init().
@MainActor
final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    private let container: ModelContainer
    private let scheduler: NotificationScheduler
    private let healthStore: HealthStore

    init(container: ModelContainer, scheduler: NotificationScheduler, healthStore: HealthStore) {
        self.container = container
        self.scheduler = scheduler
        self.healthStore = healthStore
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Routes action-button taps from lock-screen / banner notifications.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            await handle(response.actionIdentifier)
            completionHandler()
        }
    }

    /// Show banner + play sound even when the app is already in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Action routing

    private func handle(_ actionIdentifier: String) async {
        let context = ModelContext(container)
        let controller = FastingController(context: context, scheduler: scheduler, healthStore: healthStore)

        switch actionIdentifier {
        case "ACTION_LOG_WATER":
            // Log a standard 250 mL (≈ 8 oz) serving
            let entry = WaterEntry(date: Date(), volumeMl: 250, source: .manual)
            context.insert(entry)
            try? context.save()
            try? await healthStore.saveWater(ml: 250)

        case "ACTION_END_FAST":
            guard let session = controller.activeFast() else { return }
            let writeToHealth = (try? context.fetch(FetchDescriptor<UserProfile>()))?.first?.writeFastsToHealthKit ?? false
            try? await controller.endFast(session, reason: .endedEarly, writeToHealthKit: writeToHealth)

        case "ACTION_START_FAST":
            guard let plan = (try? context.fetch(FetchDescriptor<FastingPlan>()))?.first else { return }
            _ = try? controller.startFast(plan: plan)

        default:
            break
        }
    }
}
