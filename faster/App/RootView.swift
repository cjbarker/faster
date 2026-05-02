import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppDependencies.self) private var deps
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.first?.hasCompletedOnboarding == true {
                MainTabs()
            } else {
                OnboardingCoordinator()
            }
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    private var resolvedColorScheme: ColorScheme? {
        switch profiles.first?.appearanceMode ?? .system {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct MainTabs: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "timer") }
            WeightLogView()
                .tabItem { Label("Weight", systemImage: "scalemass") }
            WaterLogView()
                .tabItem { Label("Water", systemImage: "drop.fill") }
            WeeklySummaryView()
                .tabItem { Label("Summary", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(AppColor.accent)
    }
}
