import Foundation
import WidgetKit

struct WidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: TimetableSnapshot
    let currentClass: ScheduledClass?
    let nextClass: ScheduledClass?
    let todayClasses: [ScheduledClass]
    let weekdayClasses: [Weekday: [ScheduledClass]]
}
