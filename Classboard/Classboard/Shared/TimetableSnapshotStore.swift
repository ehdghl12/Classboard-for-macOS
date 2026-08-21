import Foundation

enum TimetableSnapshotStoreError: LocalizedError {
    case appGroupContainerUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .appGroupContainerUnavailable(let identifier):
            "App Group container is unavailable for \(identifier). Check Signing & Capabilities for the main app and widget extension."
        }
    }
}

struct TimetableSnapshotStore {
    var appGroupIdentifier: String = AppConfiguration.appGroupIdentifier
    var fileManager: FileManager = .default
    var overrideContainerURL: URL?

    func load(source: String = "Widget") -> TimetableSnapshot {
        do {
            let url = try snapshotURL(source: source)
            guard fileManager.fileExists(atPath: url.path) else {
                debugLog("[\(source)] snapshot exists = false")
                debugLog("[\(source)] snapshot file missing: \(url.path)")
                return .empty
            }

            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? NSNumber
            debugLog("[\(source)] snapshot exists = true")
            debugLog("[\(source)] snapshot size = \(fileSize?.intValue ?? 0) bytes")
            let snapshot = try decodeSnapshot(at: url)
            debugLog("[\(source)] snapshot loaded: \(snapshot.courses.count) courses / \(snapshot.scheduledClassCount) scheduled classes")
            return snapshot
        } catch {
            debugLog("[\(source)] snapshot load failed: \(error.localizedDescription)")
            return .empty
        }
    }

    func save(_ snapshot: TimetableSnapshot) throws {
        let url = try snapshotURL(source: "WidgetSync")
        debugLog("[WidgetSync] courses: \(snapshot.courses.count)")
        debugLog("[WidgetSync] scheduledClasses: \(snapshot.scheduledClassCount)")
        debugLog("[WidgetSync] writing snapshot to: \(url.path)")
        logScheduledClasses(snapshot)

        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])

        let verifiedSnapshot = try decodeSnapshot(at: url)
        debugLog("[WidgetSync] verified snapshot read-back: \(verifiedSnapshot.courses.count) courses / \(verifiedSnapshot.scheduledClassCount) scheduled classes")
    }

    func snapshotURL(source: String = "WidgetSync") throws -> URL {
        try containerURL(source: source).appendingPathComponent(AppConfiguration.snapshotFileName)
    }

    private func containerURL(source: String) throws -> URL {
        debugLog("[\(source)] App Group: \(appGroupIdentifier)")

        if let overrideContainerURL {
            debugLog("[\(source)] Container: \(overrideContainerURL.path)")
            return overrideContainerURL
        }

        if let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            debugLog("[\(source)] Container: \(url.path)")
            return url
        }

        debugLog("[\(source)] Container: nil")
        throw TimetableSnapshotStoreError.appGroupContainerUnavailable(appGroupIdentifier)
    }

    private func decodeSnapshot(at url: URL) throws -> TimetableSnapshot {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TimetableSnapshot.self, from: data)
    }

    private func logScheduledClasses(_ snapshot: TimetableSnapshot) {
        for course in snapshot.courses {
            for schedule in course.schedules {
                debugLog(
                    "[WidgetSync] class courseID=\(course.id.uuidString) name=\(course.name) professor=\(course.professor ?? "-") location=\(course.location ?? "-") weekday=\(schedule.weekday.shortName) start=\(schedule.startTime.displayText) end=\(schedule.endTime.displayText) color=\(course.colorHex)"
                )
            }
        }
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
}
