import SwiftUI

struct SafetyScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Health") {
                Toggle("Are you pregnant or breastfeeding?", isOn: $state.isPregnantOrBreastfeeding)
            }
            Section("Questions about eating") {
                Toggle("Do you make yourself sick because you feel uncomfortably full?", isOn: $state.scoffSickAfterEating)
                Toggle("Do you worry you've lost control over how much you eat?", isOn: $state.scoffLostControlEating)
            }
            Section("Medications") {
                Toggle("Insulin or sulfonylureas (diabetes)", isOn: $state.takesInsulinOrSulfonylureas)
                Toggle("Blood pressure medications", isOn: $state.takesBPMeds)
                Toggle("Any medication taken with food", isOn: $state.takesMedsWithFood)
            }
            Section("Experience") {
                Toggle("I have previously done fasts of 12+ hours", isOn: $state.hasFastingExperience)
            }
            if let reason = state.hardBlockReason {
                Section {
                    Text(reason).foregroundStyle(AppColor.destructive)
                }
            } else if let reason = state.softBlockReason {
                Section {
                    Text(reason).foregroundStyle(.orange)
                }
            } else if state.needsMedicalAcknowledgment {
                Section {
                    Text("Because you take medications that may be affected by fasting, please confirm with your healthcare provider before continuing. faster can still guide you, but the plan is not a substitute for clinical advice.")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Safety check")
        .toolbar { OnboardingToolbar(state: state) }
    }
}
