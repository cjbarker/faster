import XCTest
@testable import faster

final class EnergyMathTests: XCTestCase {
    // Reference values from Mifflin-St Jeor (1990).
    // Male, 80 kg, 180 cm, 30 yrs → 10·80 + 6.25·180 − 5·30 + 5 = 800 + 1125 − 150 + 5 = 1780
    func testBMRMale() {
        let bmr = EnergyMath.bmr(sex: .male, weightKg: 80, heightCm: 180, ageYears: 30)
        XCTAssertEqual(bmr, 1780, accuracy: 0.001)
    }
    // Female, 60 kg, 165 cm, 30 yrs → 10·60 + 6.25·165 − 5·30 − 161 = 600 + 1031.25 − 150 − 161 = 1320.25
    func testBMRFemale() {
        let bmr = EnergyMath.bmr(sex: .female, weightKg: 60, heightCm: 165, ageYears: 30)
        XCTAssertEqual(bmr, 1320.25, accuracy: 0.001)
    }
    func testTDEE() {
        let tdee = EnergyMath.tdee(bmr: 1780, activity: .moderate)
        XCTAssertEqual(tdee, 1780 * 1.55, accuracy: 0.001)
    }
    func testCalorieTargetAppliesFloor() {
        // Extreme: tiny TDEE forces floor.
        let target = EnergyMath.targetDailyCalories(tdee: 1000, sex: .female, currentWeightKg: 50)
        XCTAssertEqual(target.calories, EnergyMath.femaleKcalFloor, accuracy: 0.001)
        XCTAssertTrue(target.hitKcalFloor)
    }
    func testCalorieTargetRespectsRateCap() {
        // High TDEE + small body → 22% deficit would exceed 1%/week loss cap.
        let target = EnergyMath.targetDailyCalories(tdee: 4000, sex: .male, currentWeightKg: 60)
        let onePctCap = 4000 - (60 * 0.01 * EnergyMath.kcalPerKgBodyFat / 7.0)
        XCTAssertGreaterThanOrEqual(target.calories, onePctCap - 0.0001)
    }
    func testProjection() {
        let days = EnergyMath.projectedDaysToGoal(currentWeightKg: 80, targetWeightKg: 75, dailyDeficit: 500)
        // 5 kg × 7700 / 500 = 77 days
        XCTAssertEqual(days, 77)
    }
    func testBMI() {
        let bmi = EnergyMath.bmi(weightKg: 70, heightCm: 175)
        XCTAssertEqual(bmi, 22.857, accuracy: 0.01)
    }
}
