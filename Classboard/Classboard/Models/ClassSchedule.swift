import Foundation
import SwiftData

@Model
final class ClassSchedule {
    @Attribute(.unique) var id: UUID
    var weekdayRawValue: Int
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int

    init(
        id: UUID = UUID(),
        weekday: Weekday,
        startTime: TimeOfDay,
        endTime: TimeOfDay
    ) {
        self.id = id
        self.weekdayRawValue = weekday.rawValue
        self.startHour = startTime.hour
        self.startMinute = startTime.minute
        self.endHour = endTime.hour
        self.endMinute = endTime.minute
    }

    var weekday: Weekday {
        get { Weekday(rawValue: weekdayRawValue) ?? .monday }
        set { weekdayRawValue = newValue.rawValue }
    }

    var startTime: TimeOfDay {
        get { TimeOfDay(hour: startHour, minute: startMinute) }
        set {
            startHour = newValue.hour
            startMinute = newValue.minute
        }
    }

    var endTime: TimeOfDay {
        get { TimeOfDay(hour: endHour, minute: endMinute) }
        set {
            endHour = newValue.hour
            endMinute = newValue.minute
        }
    }
}
