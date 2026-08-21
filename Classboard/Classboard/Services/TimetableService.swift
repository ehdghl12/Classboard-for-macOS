import Foundation

enum TimetableService {
    static func snapshot(from courses: [Course]) -> TimetableSnapshot {
        let courseSnapshots = courses.map { course in
            CourseSnapshot(
                id: course.id,
                name: course.name,
                professor: normalizedOptional(course.professor),
                location: normalizedOptional(course.location),
                colorHex: course.colorHex,
                schedules: course.schedules.map { schedule in
                    ClassScheduleSnapshot(
                        id: schedule.id,
                        weekday: schedule.weekday,
                        startTime: schedule.startTime,
                        endTime: schedule.endTime
                    )
                }
                .sorted {
                    if $0.weekday == $1.weekday {
                        return $0.startTime < $1.startTime
                    }
                    return $0.weekday < $1.weekday
                },
                createdAt: course.createdAt
            )
        }

        return TimetableSnapshot(courses: courseSnapshots, generatedAt: Date())
    }

    static func snapshotsByCourse(from courses: [Course]) -> [CourseSnapshot] {
        snapshot(from: courses).courses
    }

    private static func normalizedOptional(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed?.isEmpty == false ? trimmed : nil
    }
}
