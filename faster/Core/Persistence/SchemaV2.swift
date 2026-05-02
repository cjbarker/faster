import Foundation
import SwiftData

/// V2 removes the never-populated NotificationLog table via lightweight migration.
enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            UserProfile.self,
            Goal.self,
            FastingPlan.self,
            FastSession.self,
            WeightEntry.self,
            WaterEntry.self
        ]
    }
}
