import Foundation

struct ScheduleCalculator {
    var courses: [CourseSnapshot]
    var calendar: Calendar

    init(courses: [CourseSnapshot], calendar: Calendar = .current) {
        self.courses = courses
        var configuredCalendar = calendar
        configuredCalendar.timeZone = calendar.timeZone
        self.calendar = configuredCalendar
    }

    func schedules(for date: Date) -> [ScheduledClass] {
        let weekday = Weekday.from(date: date, calendar: calendar)

        return courses.flatMap { course in
            course.schedules.compactMap { schedule -> ScheduledClass? in
                guard schedule.weekday == weekday,
                      schedule.endTime > schedule.startTime,
                      let startDate = schedule.startTime.date(on: date, calendar: calendar),
                      let endDate = schedule.endTime.date(on: date, calendar: calendar)
                else {
                    return nil
                }

                let dayStamp = calendar.startOfDay(for: date).timeIntervalSinceReferenceDate
                return ScheduledClass(
                    occurrenceID: "\(course.id.uuidString)-\(schedule.id.uuidString)-\(Int(dayStamp))",
                    courseID: course.id,
                    scheduleID: schedule.id,
                    courseName: course.name,
                    professor: course.professor,
                    location: course.location,
                    colorHex: course.colorHex,
                    weekday: schedule.weekday,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    startDate: startDate,
                    endDate: endDate
                )
            }
        }
        .sorted {
            if $0.startTime == $1.startTime {
                return $0.courseName.localizedCompare($1.courseName) == .orderedAscending
            }
            return $0.startTime < $1.startTime
        }
    }

    func currentClass(at date: Date) -> ScheduledClass? {
        schedules(for: date).first { $0.isHappening(at: date) }
    }

    func nextClass(after date: Date) -> ScheduledClass? {
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) else {
                continue
            }

            let candidates = schedules(for: day)
            if offset == 0 {
                if let nextToday = candidates.first(where: { $0.startDate > date }) {
                    return nextToday
                }
            } else if let firstClass = candidates.first {
                return firstClass
            }
        }

        return nil
    }

    func classes(on weekday: Weekday, inWeekOf date: Date) -> [ScheduledClass] {
        schedules(for: representativeDate(for: weekday, inWeekOf: date))
    }

    func weekdayScheduleMondayToFriday(inWeekOf date: Date) -> [Weekday: [ScheduledClass]] {
        Dictionary(
            uniqueKeysWithValues: Weekday.weekdays.map { weekday in
                (weekday, classes(on: weekday, inWeekOf: date))
            }
        )
    }

    func timelineChangeDates(from date: Date, days: Int = 7) -> [Date] {
        var result: [Date] = [date]

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) else {
                continue
            }

            if day > date {
                result.append(day)
            }

            for scheduledClass in schedules(for: day) {
                if scheduledClass.startDate >= date {
                    result.append(scheduledClass.startDate)
                }
                if scheduledClass.endDate >= date {
                    result.append(scheduledClass.endDate)
                }
            }
        }

        return Array(Set(result.map { roundedToMinute($0) })).sorted()
    }

    private func representativeDate(for weekday: Weekday, inWeekOf date: Date) -> Date {
        let currentWeekday = Weekday.from(date: date, calendar: calendar)
        let distance = weekday.rawValue - currentWeekday.rawValue
        return calendar.date(byAdding: .day, value: distance, to: calendar.startOfDay(for: date)) ?? date
    }

    private func roundedToMinute(_ date: Date) -> Date {
        let seconds = calendar.component(.second, from: date)
        guard seconds != 0 else { return date }
        return calendar.date(byAdding: .second, value: -seconds, to: date) ?? date
    }
}
