import WidgetKit

struct TimetableTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        entry(for: Date(), snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let snapshot = context.isPreview ? TimetableSnapshot.preview : TimetableSnapshotStore().load(source: "WidgetSnapshot")
        completion(entry(for: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        debugLog("getTimeline called")
        let snapshot = TimetableSnapshotStore().load(source: "WidgetTimeline")
        let calculator = ScheduleCalculator(courses: snapshot.courses)
        let now = Date()
        let changeDates = calculator.timelineChangeDates(from: now, days: 14)
        let entries = changeDates.prefix(32).map { entry(for: $0, snapshot: snapshot) }
        if let firstEntry = entries.first {
            debugLogTimeline(snapshot: snapshot, entry: firstEntry)
        }
        let nextRefresh = changeDates.dropFirst().first ?? Calendar.current.date(byAdding: .hour, value: 6, to: now) ?? now
        completion(Timeline(entries: entries, policy: .after(nextRefresh)))
    }

    private func entry(for date: Date, snapshot: TimetableSnapshot) -> WidgetEntry {
        let calculator = ScheduleCalculator(courses: snapshot.courses)
        return WidgetEntry(
            date: date,
            snapshot: snapshot,
            currentClass: calculator.currentClass(at: date),
            nextClass: calculator.nextClass(after: date),
            todayClasses: calculator.schedules(for: date),
            weekdayClasses: calculator.weekdayScheduleMondayToFriday(inWeekOf: date)
        )
    }

    private func debugLogTimeline(snapshot: TimetableSnapshot, entry: WidgetEntry) {
        #if DEBUG
        let weekdayClassCount = entry.weekdayClasses.values.reduce(0) { count, classes in
            count + classes.count
        }
        print("[Widget Timeline] snapshot courses = \(snapshot.courses.count)")
        print("[Widget Timeline] snapshot scheduledClasses = \(snapshot.scheduledClassCount)")
        print("[Widget Timeline] entry todayClasses = \(entry.todayClasses.count)")
        print("[Widget Timeline] entry weekdayClasses = \(weekdayClassCount)")
        print("[Widget Timeline] entry nextClass = \(entry.nextClass?.courseName ?? "nil")")
        #endif
    }

    private func debugLog(_ message: String) {
        #if DEBUG
        print("[Widget Timeline] \(message)")
        #endif
    }
}
