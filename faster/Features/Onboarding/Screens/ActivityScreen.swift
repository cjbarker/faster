import SwiftUI

struct ActivityScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Typical week") {
                Picker("Activity level", selection: $state.activityLevel) {
                    Text("Sedentary (desk job, no exercise)").tag(ActivityLevel.sedentary)
                    Text("Light (1–3 days/week)").tag(ActivityLevel.light)
                    Text("Moderate (3–5 days/week)").tag(ActivityLevel.moderate)
                    Text("Active (6–7 days/week)").tag(ActivityLevel.active)
                    Text("Very active (hard training)").tag(ActivityLevel.veryActive)
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            Section {
                Text("We use this plus your weight, height, and age to estimate your daily calorie needs.")
                    .foregroundStyle(.secondary)
                    .font(AppFont.caption)
            }
        }
        .navigationTitle("Activity")
        .toolbar { OnboardingToolbar(state: state) }
    }
}
