#if canImport(HealthKit)
import HealthKit

enum HealthKitTypes {
    static var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = []
        if let bodyMass  = HKObjectType.quantityType(forIdentifier: .bodyMass)       { set.insert(bodyMass) }
        if let water     = HKObjectType.quantityType(forIdentifier: .dietaryWater)   { set.insert(water) }
        if let mindful   = HKObjectType.categoryType(forIdentifier: .mindfulSession) { set.insert(mindful) }
        return set
    }

    static var writeTypes: Set<HKSampleType> {
        var set: Set<HKSampleType> = []
        if let bodyMass  = HKObjectType.quantityType(forIdentifier: .bodyMass)       { set.insert(bodyMass) }
        if let water     = HKObjectType.quantityType(forIdentifier: .dietaryWater)   { set.insert(water) }
        if let mindful   = HKObjectType.categoryType(forIdentifier: .mindfulSession) { set.insert(mindful) }
        return set
    }
}
#endif
