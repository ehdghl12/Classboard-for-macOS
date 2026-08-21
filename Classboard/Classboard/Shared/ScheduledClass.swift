import Foundation

struct ScheduledClass: Hashable, Identifiable, Sendable {
    var occurrenceID: String
    var courseID: UUID
    var scheduleID: UUID
    var courseName: String
    var professor: String?
    var location: String?
    var colorHex: String
    var weekday: Weekday
    var startTime: TimeOfDay
    var endTime: TimeOfDay
    var startDate: Date
    var endDate: Date

    var id: String { occurrenceID }

    var timeRangeText: String {
        "\(startTime.displayText) - \(endTime.displayText)"
    }

    func isHappening(at date: Date) -> Bool {
        startDate <= date && date < endDate
    }
}
