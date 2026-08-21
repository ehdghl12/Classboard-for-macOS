import Foundation

enum DateTimeHelper {
    static func minutesUntil(_ date: Date, from now: Date = Date()) -> Int {
        max(0, Int(ceil(date.timeIntervalSince(now) / 60)))
    }

    static func relativeClassText(for scheduledClass: ScheduledClass, from now: Date = Date(), calendar: Calendar = .current) -> String {
        if calendar.isDate(scheduledClass.startDate, inSameDayAs: now) {
            let minutes = minutesUntil(scheduledClass.startDate, from: now)
            if minutes < 60 {
                return "\(minutes)분 후"
            }
            return "\(minutes / 60)시간 \(minutes % 60)분 후"
        }

        if calendar.isDateInTomorrow(scheduledClass.startDate) {
            return "내일 \(scheduledClass.startTime.displayText)"
        }

        return "\(scheduledClass.weekday.shortName) \(scheduledClass.startTime.displayText)"
    }
}
