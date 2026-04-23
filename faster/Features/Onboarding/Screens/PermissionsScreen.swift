import SwiftUI

struct PermissionsScreen: View {
    @Bindable var state: OnboardingState
    @Environment(AppDependencies.self) private var deps
    @State private var healthRequested = false
    @State private var notificationsRequested = false

    var body: some View {
        Form {
            Section("Notifications") {
                Text("We'll let you know when your fast starts, when it's about to end, and when to hydrate.")
                    .foregroundStyle(.secondary)
                    .font(AppFont.caption)
                Button(notificationsRequested ? "Requested" : "Enable notifications") {
                    Task {
                        _ = await deps.notificationScheduler.requestAuthorization()
                        notificationsRequested = true
                    }
                }
                .disabled(notificationsRequested)
            }
            Section("Apple Health") {
                Text("Optional. Connect to pull your weight and share fasting sessions with Health.")
                    .foregroundStyle(.secondary)
                    .font(AppFont.caption)
                Button(healthRequested ? "Requested" : "Connect Apple Health") {
                    Task {
                        try? await deps.healthStore.requestAuthorization()
                        healthRequested = true
                    }
                }
                .disabled(healthRequested || !deps.healthStore.isAvailable)
            }
        }
        .navigationTitle("Permissions")
        .toolbar { OnboardingToolbar(state: state) }
    }
}
