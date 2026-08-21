import Foundation

struct ScheduleDraft: Identifiable, Hashable {
    var id: UUID = UUID()
    var weekday: Weekday = .monday
    var startDate: Date = ScheduleDraft.date(hour: 10, minute: 0)
    var endDate: Date = ScheduleDraft.date(hour: 11, minute: 0)

    var startTime: TimeOfDay {
        TimeOfDay.from(date: startDate)
    }

    var endTime: TimeOfDay {
        TimeOfDay.from(date: endDate)
    }

    var startHour: Int {
        get { startTime.hour }
        set { startDate = ScheduleDraft.date(hour: newValue, minute: 0) }
    }

    var startMinute: Int {
        get { startTime.minute }
        set { startDate = ScheduleDraft.date(hour: startHour, minute: newValue) }
    }

    var endHour: Int {
        get { endTime.hour }
        set { endDate = ScheduleDraft.date(hour: newValue, minute: 0) }
    }

    var endMinute: Int {
        get { endTime.minute }
        set { endDate = ScheduleDraft.date(hour: endHour, minute: newValue) }
    }

    static func from(schedule: ClassSchedule) -> ScheduleDraft {
        ScheduleDraft(
            id: schedule.id,
            weekday: schedule.weekday,
            startDate: date(hour: schedule.startTime.hour, minute: schedule.startTime.minute),
            endDate: date(hour: schedule.endTime.hour, minute: schedule.endTime.minute)
        )
    }

    static func date(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar.current
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute
        return components.date ?? Date()
    }
}
