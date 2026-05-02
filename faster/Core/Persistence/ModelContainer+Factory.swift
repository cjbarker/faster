import Foundation
import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: FasterMigrationPlan.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}

enum FasterMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] {
        // Lightweight migration drops the empty NotificationLog table.
        [.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)]
    }
}
