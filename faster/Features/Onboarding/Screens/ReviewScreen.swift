import SwiftUI

struct ReviewScreen: View {
    @Bindable var state: OnboardingState
    var onFinish: () -> Void

    var body: some View {
        Form {
            Section("Your plan") {
                row("Protocol", state.protocolKind.rawValue)
                row("Eating window", eatingWindowLabel)
                row("Activity", state.activityLevel.rawValue.capitalized)
            }
            Section("Energy") {
                let bmr = EnergyMath.bmr(sex: state.sex, weightKg: state.currentWeightKg, heightCm: state.heightCm, ageYears: state.ageYears)
                let tdee = EnergyMath.tdee(bmr: bmr, activity: state.activityLevel)
                let target = EnergyMath.targetDailyCalories(tdee: tdee, sex: state.sex, currentWeightKg: state.currentWeightKg)
                row("BMR", "\(Int(bmr.rounded())) kcal")
                row("TDEE", "\(Int(tdee.rounded())) kcal")
                row("Daily target", "\(Int(target.calories.rounded())) kcal")
                row("Daily deficit", "\(Int(target.deficit.rounded())) kcal")
                if target.hitKcalFloor {
                    Text("Target raised to the safe floor (\(Int((state.sex == .male ? EnergyMath.maleKcalFloor : EnergyMath.femaleKcalFloor))) kcal).")
                        .foregroundStyle(.orange).font(AppFont.caption)
                }
                if target.hitRateCap {
                    Text("Target raised to keep weight loss under ~1%/week.")
                        .foregroundStyle(.orange).font(AppFont.caption)
                }
                if let days = EnergyMath.projectedDaysToGoal(currentWeightKg: state.currentWeightKg, targetWeightKg: state.targetWeightKg, dailyDeficit: target.deficit) {
                    row("Projected", "~\(days) days to goal")
                }
            }
            Section {
                Button("Start your first fast") {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Back") { retreat(state) }
            }
        }
    }

    private var eatingWindowLabel: String {
        let start = state.eatingWindowStartMinutes
        let endRaw = (start + state.protocolKind.eatingHours * 60) % (24 * 60)
        return "\(formatMinutes(start)) – \(formatMinutes(endRaw))"
    }
    private func formatMinutes(_ m: Int) -> String {
        String(format: "%d:%02d", m / 60, m % 60)
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(.secondary) }
    }
}
