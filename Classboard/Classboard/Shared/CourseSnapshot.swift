import Foundation

struct TimetableSnapshot: Codable, Hashable, Sendable {
    var courses: [CourseSnapshot]
    var generatedAt: Date

    static let empty = TimetableSnapshot(courses: [], generatedAt: .distantPast)

    var isEmpty: Bool {
        courses.isEmpty
    }

    var scheduledClassCount: Int {
        courses.reduce(0) { count, course in
            count + course.schedules.count
        }
    }
}

struct CourseSnapshot: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var professor: String?
    var location: String?
    var colorHex: String
    var schedules: [ClassScheduleSnapshot]
    var createdAt: Date
}

struct ClassScheduleSnapshot: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var weekday: Weekday
    var startTime: TimeOfDay
    var endTime: TimeOfDay
}

extension TimetableSnapshot {
    static let preview = TimetableSnapshot(
        courses: [
            CourseSnapshot(
                id: UUID(),
                name: "자료구조",
                professor: "김교수",
                location: "공학관 302호",
                colorHex: "#4F7DFF",
                schedules: [
                    ClassScheduleSnapshot(id: UUID(), weekday: .monday, startTime: TimeOfDay(hour: 10, minute: 30), endTime: TimeOfDay(hour: 11, minute: 45)),
                    ClassScheduleSnapshot(id: UUID(), weekday: .wednesday, startTime: TimeOfDay(hour: 10, minute: 30), endTime: TimeOfDay(hour: 11, minute: 45))
                ],
                createdAt: Date()
            ),
            CourseSnapshot(
                id: UUID(),
                name: "운영체제",
                professor: "박교수",
                location: "공학관 201호",
                colorHex: "#2AA889",
                schedules: [
                    ClassScheduleSnapshot(id: UUID(), weekday: .tuesday, startTime: TimeOfDay(hour: 9, minute: 0), endTime: TimeOfDay(hour: 10, minute: 15)),
                    ClassScheduleSnapshot(id: UUID(), weekday: .thursday, startTime: TimeOfDay(hour: 9, minute: 0), endTime: TimeOfDay(hour: 10, minute: 15))
                ],
                createdAt: Date()
            ),
            CourseSnapshot(
                id: UUID(),
                name: "데이터베이스",
                professor: nil,
                location: "IT관 401호",
                colorHex: "#E26D5A",
                schedules: [
                    ClassScheduleSnapshot(id: UUID(), weekday: .friday, startTime: TimeOfDay(hour: 13, minute: 0), endTime: TimeOfDay(hour: 14, minute: 15))
                ],
                createdAt: Date()
            )
        ],
        generatedAt: Date()
    )
}
