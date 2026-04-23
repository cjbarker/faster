import SwiftUI
import SwiftData

enum OnboardingStep: Int, CaseIterable {
    case disclaimer, demographics, activity, goal, safety, `protocol`, window, permissions, review
}

@Observable
@MainActor
final class OnboardingState {
    var step: OnboardingStep = .disclaimer
    var acknowledgedDisclaimer = false

    // Demographics
    var sex: Sex = .unspecified
    var dateOfBirth: Date = Calendar.current.date(byAdding: .year, value: -35, to: Date()) ?? Date()
    var heightCm: Double = 170
    var currentWeightKg: Double = 75
    var unitSystem: UnitSystem = .imperial
    var activityLevel: ActivityLevel = .moderate

    // Goal
    var targetWeightKg: Double = 70
    var targetDate: Date? = Calendar.current.date(byAdding: .month, value: 3, to: Date())

    // Safety
    var isPregnantOrBreastfeeding: Bool = false
    var scoffSickAfterEating: Bool = false
    var scoffLostControlEating: Bool = false
    var takesInsulinOrSulfonylureas: Bool = false
    var takesBPMeds: Bool = false
    var takesMedsWithFood: Bool = false
    var hasFastingExperience: Bool = false

    // Protocol
    var protocolKind: ProtocolKind = .sixteenEight

    // Eating window
    var eatingWindowStartMinutes: Int = 12 * 60

    // Derived
    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
    var bmi: Double {
        EnergyMath.bmi(weightKg: currentWeightKg, heightCm: heightCm)
    }
    var targetBmi: Double {
        EnergyMath.bmi(weightKg: targetWeightKg, heightCm: heightCm)
    }
    var hardBlockReason: String? {
        if ageYears < 18 { return "faster requires users to be 18 or older." }
        if isPregnantOrBreastfeeding { return "Intermittent fasting isn't recommended during pregnancy or breastfeeding. Please consult a clinician." }
        if bmi < 18.5 { return "Your current BMI is below the safe range for weight-loss fasting. Please consult a clinician." }
        if targetBmi < 18.5 { return "Your goal weight would put you below the safe BMI range. Please choose a higher target." }
        return nil
    }
    var softBlockReason: String? {
        if scoffSickAfterEating || scoffLostControlEating {
            return "Your answers suggest you should speak to a healthcare provider before starting. If you're in the US, you can reach NEDA at 1-800-931-2237."
        }
        return nil
    }
    var needsMedicalAcknowledgment: Bool {
        takesInsulinOrSulfonylureas || takesBPMeds || takesMedsWithFood
    }
    var requiresExperience: Bool { protocolKind.requiresExperience }

    func commit(to context: ModelContext) {
        let profile = UserProfile(
            sex: sex,
            dateOfBirth: dateOfBirth,
            heightCm: heightCm,
            activityLevel: activityLevel,
            unitSystem: unitSystem
        )
        profile.hasAcknowledgedDisclaimer = acknowledgedDisclaimer
        profile.hasCompletedOnboarding = true
        var flags: [String] = []
        if takesInsulinOrSulfonylureas { flags.append("insulin_or_sulfonylureas") }
        if takesBPMeds { flags.append("bp_meds") }
        if takesMedsWithFood { flags.append("meds_with_food") }
        profile.medicalFlags = flags
        context.insert(profile)

        let goal = Goal(targetWeightKg: targetWeightKg, targetDate: targetDate)
        context.insert(goal)

        let plan = FastingPlan(
            protocolKind: protocolKind,
            eatingWindowStartMinutes: eatingWindowStartMinutes
        )
        context.insert(plan)

        let weight = WeightEntry(date: Date(), weightKg: currentWeightKg, source: .manual)
        context.insert(weight)

        try? context.save()
    }
}

struct OnboardingCoordinator: View {
    @State private var state = OnboardingState()
    @Environment(\.modelContext) private var context
    @Environment(AppDependencies.self) private var deps

    var body: some View {
        NavigationStack {
            Group {
                switch state.step {
                case .disclaimer:    DisclaimerScreen(state: state)
                case .demographics:  DemographicsScreen(state: state)
                case .activity:      ActivityScreen(state: state)
                case .goal:          GoalScreen(state: state)
                case .safety:        SafetyScreen(state: state)
                case .protocol:      ProtocolScreen(state: state)
                case .window:        WindowScreen(state: state)
                case .permissions:   PermissionsScreen(state: state)
                case .review:        ReviewScreen(state: state, onFinish: finish)
                }
            }
            .animation(.default, value: state.step)
        }
    }

    private func finish() {
        state.commit(to: context)
        Task {
            await deps.notificationScheduler.registerCategories()
        }
    }
}

func advance(_ state: OnboardingState) {
    let next = min(state.step.rawValue + 1, OnboardingStep.allCases.count - 1)
    state.step = OnboardingStep(rawValue: next) ?? .review
}

func retreat(_ state: OnboardingState) {
    let prev = max(state.step.rawValue - 1, 0)
    state.step = OnboardingStep(rawValue: prev) ?? .disclaimer
}
