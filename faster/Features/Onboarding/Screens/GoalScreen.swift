import SwiftUI

struct GoalScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Goal weight") {
                WeightField(label: "Target weight", kg: $state.targetWeightKg, unitSystem: state.unitSystem)
                HStack {
                    Text("Current BMI")
                    Spacer()
                    Text(String(format: "%.1f", state.bmi)).foregroundStyle(.secondary)
                }
                HStack {
                    Text("Target BMI")
                    Spacer()
                    Text(String(format: "%.1f", state.targetBmi)).foregroundStyle(.secondary)
                }
            }
            Section("Timeline") {
                DatePicker(
                    "Target date",
                    selection: Binding(
                        get: { state.targetDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date() },
                        set: { state.targetDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
            }
            if let reason = state.hardBlockReason {
                Section {
                    Text(reason)
                        .foregroundStyle(AppColor.destructive)
                }
            }
        }
        .navigationTitle("Your goal")
        .toolbar { OnboardingToolbar(state: state) }
    }
}
