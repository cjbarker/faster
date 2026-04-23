import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            Goal.self,
            FastingPlan.self,
            FastSession.self,
            WeightEntry.self,
            WaterEntry.self,
            NotificationLog.self
        ]
    }
}

enum Sex: String, Codable, CaseIterable, Sendable {
    case male, female, unspecified
}

enum ActivityLevel: String, Codable, CaseIterable, Sendable {
    case sedentary, light, moderate, active, veryActive

    var multiplier: Double {
        switch self {
        case .sedentary:   return 1.2
        case .light:       return 1.375
        case .moderate:    return 1.55
        case .active:      return 1.725
        case .veryActive:  return 1.9
        }
    }
}

enum UnitSystem: String, Codable, CaseIterable, Sendable {
    case metric, imperial
}

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system, light, dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

enum ProtocolKind: String, Codable, CaseIterable, Sendable {
    case sixteenEight = "16:8"
    case eighteenSix  = "18:6"
    case twentyFour   = "20:4"
    case omad         = "OMAD"

    var fastingHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix:  return 18
        case .twentyFour:   return 20
        case .omad:         return 23
        }
    }

    var eatingHours: Int { 24 - fastingHours }
    var requiresExperience: Bool { self == .twentyFour || self == .omad }
}

enum FastEndReason: String, Codable, Sendable {
    case completed, endedEarly, missed, adjusted
}

enum WeightSource: String, Codable, Sendable {
    case manual, healthKit
}

enum WaterSource: String, Codable, Sendable {
    case manual, healthKit
}

@Model
final class UserProfile {
    var sex: Sex = Sex.unspecified
    var dateOfBirth: Date = Date.distantPast
    var heightCm: Double = 170
    var activityLevel: ActivityLevel = ActivityLevel.moderate
    var unitSystem: UnitSystem = UnitSystem.imperial
    var appearanceMode: AppearanceMode = AppearanceMode.system
    var hasAcknowledgedDisclaimer: Bool = false
    var hasCompletedOnboarding: Bool = false
    var writeFastsToHealthKit: Bool = false
    var medicalFlags: [String] = []
    var createdAt: Date = Date()

    init(sex: Sex = .unspecified,
         dateOfBirth: Date = .distantPast,
         heightCm: Double = 170,
         activityLevel: ActivityLevel = .moderate,
         unitSystem: UnitSystem = .imperial) {
        self.sex = sex
        self.dateOfBirth = dateOfBirth
        self.heightCm = heightCm
        self.activityLevel = activityLevel
        self.unitSystem = unitSystem
    }

    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }
}

@Model
final class Goal {
    var targetWeightKg: Double = 0
    var targetDate: Date?
    var rationale: String = ""
    var createdAt: Date = Date()

    init(targetWeightKg: Double, targetDate: Date?, rationale: String = "") {
        self.targetWeightKg = targetWeightKg
        self.targetDate = targetDate
        self.rationale = rationale
    }
}

@Model
final class FastingPlan {
    var protocolKind: ProtocolKind = ProtocolKind.sixteenEight
    // Eating-window start stored as minutes-from-midnight in the user's local calendar.
    var eatingWindowStartMinutes: Int = 12 * 60
    var hydrationNudgesEnabled: Bool = true
    var electrolyteRemindersEnabled: Bool = true
    var dailyWeighInEnabled: Bool = true
    var createdAt: Date = Date()

    init(protocolKind: ProtocolKind = .sixteenEight,
         eatingWindowStartMinutes: Int = 12 * 60) {
        self.protocolKind = protocolKind
        self.eatingWindowStartMinutes = eatingWindowStartMinutes
    }
}

@Model
final class FastSession {
    @Attribute(.unique) var id: UUID = UUID()
    var protocolKind: ProtocolKind = ProtocolKind.sixteenEight
    var plannedStart: Date = Date()
    var plannedEnd: Date = Date()
    var actualStart: Date = Date()
    var actualEnd: Date?
    var endReason: FastEndReason?
    var moodAtBreakFast: Int?        // 1–5
    var energyAtBreakFast: Int?      // 1–5
    var notes: String = ""

    init(protocolKind: ProtocolKind,
         plannedStart: Date,
         plannedEnd: Date,
         actualStart: Date) {
        self.protocolKind = protocolKind
        self.plannedStart = plannedStart
        self.plannedEnd = plannedEnd
        self.actualStart = actualStart
    }

    var isActive: Bool { actualEnd == nil }
    var durationSeconds: TimeInterval {
        (actualEnd ?? Date()).timeIntervalSince(actualStart)
    }
    var targetDurationSeconds: TimeInterval {
        plannedEnd.timeIntervalSince(plannedStart)
    }
    var completionRatio: Double {
        guard targetDurationSeconds > 0 else { return 0 }
        return min(1.0, durationSeconds / targetDurationSeconds)
    }
}

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = Date()
    var weightKg: Double = 0
    var source: WeightSource = WeightSource.manual

    init(date: Date, weightKg: Double, source: WeightSource) {
        self.date = date
        self.weightKg = weightKg
        self.source = source
    }
}

@Model
final class WaterEntry {
    @Attribute(.unique) var id: UUID = UUID()
    var date: Date = Date()
    var volumeMl: Double = 0
    var source: WaterSource = WaterSource.manual

    init(date: Date, volumeMl: Double, source: WaterSource) {
        self.date = date
        self.volumeMl = volumeMl
        self.source = source
    }
}

@Model
final class NotificationLog {
    @Attribute(.unique) var id: UUID = UUID()
    var type: String = ""
    var scheduledFor: Date = Date()
    var firedAt: Date?

    init(id: UUID = UUID(), type: String, scheduledFor: Date) {
        self.id = id
        self.type = type
        self.scheduledFor = scheduledFor
    }
}
