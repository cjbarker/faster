import Foundation

public enum Hydration {
    /// Daily water target in mL. Baseline 35 mL/kg; +500 mL on active days.
    public static func dailyTargetMl(weightKg: Double, isActiveDay: Bool = false) -> Double {
        let base = weightKg * 35.0
        return isActiveDay ? base + 500 : base
    }

    /// Recommended water per hour during an active fast, in mL.
    public static func hourlyFastingTargetMl(weightKg: Double) -> Double {
        // Spread 70% of daily target across waking hours (~16h).
        (dailyTargetMl(weightKg: weightKg) * 0.7) / 16.0
    }

    /// Whether electrolyte supplementation is recommended at this fast duration.
    public static func shouldRecommendElectrolytes(hoursElapsed: Double) -> Bool {
        hoursElapsed >= 12
    }
}
