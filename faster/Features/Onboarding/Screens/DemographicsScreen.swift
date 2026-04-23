import SwiftUI

struct DemographicsScreen: View {
    @Bindable var state: OnboardingState

    var body: some View {
        Form {
            Section("Units") {
                Picker("Unit system", selection: $state.unitSystem) {
                    Text("Imperial").tag(UnitSystem.imperial)
                    Text("Metric").tag(UnitSystem.metric)
                }
                .pickerStyle(.segmented)
            }

            Section("About you") {
                Picker("Sex", selection: $state.sex) {
                    Text("Female").tag(Sex.female)
                    Text("Male").tag(Sex.male)
                    Text("Prefer not to say").tag(Sex.unspecified)
                }
                DatePicker(
                    "Date of birth",
                    selection: $state.dateOfBirth,
                    in: ...(Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()),
                    displayedComponents: .date
                )
                HeightField(cm: $state.heightCm, unitSystem: state.unitSystem)
                WeightField(label: "Current weight", kg: $state.currentWeightKg, unitSystem: state.unitSystem)
            }
        }
        .navigationTitle("About you")
        .toolbar { OnboardingToolbar(state: state) }
    }
}

struct HeightField: View {
    @Binding var cm: Double
    var unitSystem: UnitSystem
    var body: some View {
        switch unitSystem {
        case .metric:
            Stepper(value: $cm, in: 120...220, step: 1) {
                HStack { Text("Height"); Spacer(); Text("\(Int(cm)) cm").foregroundStyle(.secondary) }
            }
        case .imperial:
            let inches = UnitConversion.cmToIn(cm)
            let feet = Int(inches) / 12
            let rem  = Int(inches) % 12
            Stepper(value: Binding(
                get: { inches.rounded() },
                set: { cm = UnitConversion.inToCm($0) }
            ), in: 48...88, step: 1) {
                HStack { Text("Height"); Spacer(); Text("\(feet)' \(rem)\"").foregroundStyle(.secondary) }
            }
        }
    }
}

struct WeightField: View {
    var label: String
    @Binding var kg: Double
    var unitSystem: UnitSystem
    var body: some View {
        switch unitSystem {
        case .metric:
            Stepper(value: $kg, in: 35...250, step: 0.1) {
                HStack { Text(label); Spacer(); Text(String(format: "%.1f kg", kg)).foregroundStyle(.secondary) }
            }
        case .imperial:
            let lb = UnitConversion.kgToLb(kg)
            Stepper(value: Binding(
                get: { lb.rounded() },
                set: { kg = UnitConversion.lbToKg($0) }
            ), in: 80...550, step: 1) {
                HStack { Text(label); Spacer(); Text("\(Int(lb.rounded())) lb").foregroundStyle(.secondary) }
            }
        }
    }
}

struct OnboardingToolbar: ToolbarContent {
    @Bindable var state: OnboardingState
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button("Back") { retreat(state) }
            Spacer()
            Button("Next") { advance(state) }
                .buttonStyle(.borderedProminent)
        }
    }
}
