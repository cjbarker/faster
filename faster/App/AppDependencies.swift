import Foundation
import SwiftData
import UserNotifications
import Observation

@Observable
@MainActor
final class AppDependencies {
    let modelContainer: ModelContainer
    let healthStore: HealthStore
    let notificationScheduler: NotificationScheduler
    let guidanceProvider: GuidanceProvider
    let exportService: ExportService
    // Retained for its lifetime so UNUserNotificationCenter delegate stays alive
    let notificationActionHandler: NotificationActionHandler

    init() {
        let container       = ModelContainerFactory.make()
        let health          = HealthStore()
        let scheduler       = NotificationScheduler()
        let handler         = NotificationActionHandler(container: container,
                                                        scheduler: scheduler,
                                                        healthStore: health)
        self.modelContainer             = container
        self.healthStore                = health
        self.notificationScheduler      = scheduler
        self.guidanceProvider           = BundleGuidanceProvider()
        self.exportService              = ExportService(container: container)
        self.notificationActionHandler  = handler

        // Set delegate before the first notification can arrive
        UNUserNotificationCenter.current().delegate = handler
    }

    func bootstrap() async {
        await notificationScheduler.registerCategories()
    }
}
