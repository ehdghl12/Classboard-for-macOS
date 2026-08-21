import Foundation
import SwiftData

enum PersistenceController {
    static let sharedModelContainer: ModelContainer = makeModelContainer()

    static func makeModelContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([
            Course.self,
            ClassSchedule.self
        ])

        let configuration = ModelConfiguration(
            "UniTimetable",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier(AppConfiguration.appGroupIdentifier),
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create SwiftData container: \(error.localizedDescription)")
        }
    }
}
