import Foundation

#if canImport(HealthKit)
import HealthKit

@MainActor
final class HealthStore {
    private let store: HKHealthStore?

    init() {
        self.store = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }

    var isAvailable: Bool { store != nil }

    func requestAuthorization() async throws {
        guard let store else { return }
        try await store.requestAuthorization(
            toShare: HealthKitTypes.writeTypes,
            read: HealthKitTypes.readTypes
        )
    }

    func latestWeight() async -> Double? {
        guard let store,
              let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil); return
                }
                let kg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    func weightHistory(days: Int = 90) async -> [(Date, Double)] {
        guard let store,
              let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
                let points: [(Date, Double)] = (samples as? [HKQuantitySample] ?? []).map { sample in
                    (sample.endDate, sample.quantity.doubleValue(for: .gramUnit(with: .kilo)))
                }
                continuation.resume(returning: points)
            }
            store.execute(query)
        }
    }

    func saveWeight(kg: Double, at date: Date = Date()) async throws {
        guard let store,
              let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
        let q = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: q, start: date, end: date)
        try await store.save(sample)
    }

    func saveWater(ml: Double, at date: Date = Date()) async throws {
        guard let store,
              let type = HKObjectType.quantityType(forIdentifier: .dietaryWater) else { return }
        let q = HKQuantity(unit: .literUnit(with: .milli), doubleValue: ml)
        let sample = HKQuantitySample(type: type, quantity: q, start: date, end: date)
        try await store.save(sample)
    }

    /// Save a completed fasting session as a Mindful Minutes entry.
    /// The user must explicitly opt-in via Settings.
    func saveFastingAsMindfulSession(start: Date, end: Date) async throws {
        guard let store,
              let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }
        let sample = HKCategorySample(
            type: type,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        try await store.save(sample)
    }
}
#else

@MainActor
final class HealthStore {
    var isAvailable: Bool { false }
    func requestAuthorization() async throws {}
    func latestWeight() async -> Double? { nil }
    func weightHistory(days: Int = 90) async -> [(Date, Double)] { [] }
    func saveWeight(kg: Double, at date: Date = Date()) async throws {}
    func saveWater(ml: Double, at date: Date = Date()) async throws {}
    func saveFastingAsMindfulSession(start: Date, end: Date) async throws {}
}

#endif
