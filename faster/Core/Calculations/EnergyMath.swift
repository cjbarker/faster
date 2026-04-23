import Foundation

public enum EnergyMath {
    public static let kcalPerKgBodyFat: Double = 7700
    public static let femaleKcalFloor: Double = 1200
    public static let maleKcalFloor: Double = 1500

    public static func bmr(sex: Sex, weightKg: Double, heightCm: Double, ageYears: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(ageYears)
        switch sex {
        case .male:         return base + 5
        case .female:       return base - 161
        case .unspecified:  return base - 78  // midpoint, flagged in UI
        }
    }

    public static func tdee(bmr: Double, activity: ActivityLevel) -> Double {
        bmr * activity.multiplier
    }

    /// Safe deficit: 20–25% of TDEE, floored at sex-appropriate minimum, capped at 1% BW/week loss.
    public static func targetDailyCalories(
        tdee: Double,
        sex: Sex,
        currentWeightKg: Double,
        deficitFraction: Double = 0.22
    ) -> DailyCalorieTarget {
        let rawTarget = tdee * (1 - deficitFraction)
        let floor: Double = (sex == .male) ? maleKcalFloor : femaleKcalFloor
        let onePctWeekCap = tdee - (currentWeightKg * 0.01 * kcalPerKgBodyFat / 7.0)
        let cappedByRate = max(rawTarget, onePctWeekCap)
        let final = max(floor, cappedByRate)
        let hitFloor = final > cappedByRate
        let hitRateCap = cappedByRate > rawTarget
        return DailyCalorieTarget(
            calories: final,
            deficit: tdee - final,
            hitKcalFloor: hitFloor,
            hitRateCap: hitRateCap
        )
    }

    /// Projected days to reach goal at the given daily deficit.
    public static func projectedDaysToGoal(
        currentWeightKg: Double,
        targetWeightKg: Double,
        dailyDeficit: Double
    ) -> Int? {
        let delta = currentWeightKg - targetWeightKg
        guard delta > 0, dailyDeficit > 0 else { return nil }
        let totalKcal = delta * kcalPerKgBodyFat
        return Int((totalKcal / dailyDeficit).rounded(.up))
    }

    public static func bmi(weightKg: Double, heightCm: Double) -> Double {
        let m = heightCm / 100.0
        guard m > 0 else { return 0 }
        return weightKg / (m * m)
    }
}

public struct DailyCalorieTarget: Sendable, Equatable {
    public let calories: Double
    public let deficit: Double
    public let hitKcalFloor: Bool
    public let hitRateCap: Bool
}

public enum UnitConversion {
    public static func lbToKg(_ lb: Double) -> Double { lb * 0.45359237 }
    public static func kgToLb(_ kg: Double) -> Double { kg / 0.45359237 }
    public static func inToCm(_ inches: Double) -> Double { inches * 2.54 }
    public static func cmToIn(_ cm: Double) -> Double { cm / 2.54 }
    public static func flOzToMl(_ oz: Double) -> Double { oz * 29.5735 }
    public static func mlToFlOz(_ ml: Double) -> Double { ml / 29.5735 }
}
