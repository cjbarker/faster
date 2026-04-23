import SwiftUI
import SwiftData

@main
struct fasterApp: App {
    @State private var dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
                .modelContainer(dependencies.modelContainer)
                .task {
                    await dependencies.bootstrap()
                }
        }
    }
}
