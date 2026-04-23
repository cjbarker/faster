import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class AppDependencies {
    let modelContainer: ModelContainer
    let healthStore: HealthStore
    let notificationScheduler: NotificationScheduler
    let guidanceProvider: GuidanceProvider
    let exportService: ExportService

    init() {
        self.modelContainer = ModelContainerFactory.make()
        self.healthStore = HealthStore()
        self.notificationScheduler = NotificationScheduler()
        self.guidanceProvider = BundleGuidanceProvider()
        self.exportService = ExportService(container: modelContainer)
    }

    func bootstrap() async {
        await notificationScheduler.registerCategories()
    }
}
