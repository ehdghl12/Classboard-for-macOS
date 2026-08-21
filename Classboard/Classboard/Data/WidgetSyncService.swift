import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetSyncService {
    static func synchronize(
        modelContext: ModelContext,
        reloadWidget: Bool = true,
        reason: String = "manual",
        preserveExistingSnapshotWhenFetchedEmpty: Bool = false
    ) {
        do {
            debugLog("sync started: \(reason)")
            let descriptor = FetchDescriptor<Course>(
                sortBy: [SortDescriptor(\Course.createdAt, order: .forward)]
            )
            let courses = try modelContext.fetch(descriptor)
            let snapshot = TimetableService.snapshot(from: courses)
            debugLog("fetched courses: \(courses.count)")
            debugLog("snapshot scheduledClasses: \(snapshot.scheduledClassCount)")

            let store = TimetableSnapshotStore()
            if preserveExistingSnapshotWhenFetchedEmpty && snapshot.isEmpty {
                let existingSnapshot = store.load(source: "WidgetSyncExisting")
                if !existingSnapshot.isEmpty {
                    debugLog("skipped empty app-launch snapshot because an existing non-empty snapshot is present")
                    if reloadWidget {
                        WidgetCenter.shared.reloadAllTimelines()
                        debugLog("requested widget reload: all timelines")
                    }
                    return
                }
            }

            try store.save(snapshot)

            if reloadWidget {
                WidgetCenter.shared.reloadAllTimelines()
                debugLog("requested widget reload: all timelines")
            }
        } catch {
            debugLog("sync failed: \(error.localizedDescription)")
            assertionFailure("Widget synchronization failed: \(error.localizedDescription)")
        }
    }

    #if DEBUG
    static func forceWidgetSync(modelContext: ModelContext) {
        synchronize(modelContext: modelContext, reloadWidget: true, reason: "force")
    }
    #endif

    private static func debugLog(_ message: String) {
        #if DEBUG
        print("[WidgetSync] \(message)")
        #endif
    }
}
