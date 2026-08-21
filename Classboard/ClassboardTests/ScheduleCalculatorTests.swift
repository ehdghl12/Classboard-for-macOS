import XCTest
@testable import Classboard

final class ScheduleCalculatorTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        calendar.locale = Locale(identifier: "ko_KR")
    }

    func testBeforeFirstClassReturnsNextClass() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let date = makeDate(year: 2026, month: 8, day: 17, hour: 8, minute: 0)
        XCTAssertNil(calculator.currentClass(at: date))
        XCTAssertEqual(calculator.nextClass(after: date)?.courseName, "자료구조")
    }

    func testCurrentClassDuringSchedule() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let date = makeDate(year: 2026, month: 8, day: 17, hour: 10, minute: 45)
        XCTAssertEqual(calculator.currentClass(at: date)?.courseName, "자료구조")
    }

    func testBetweenClassesReturnsLaterClass() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse(), databaseCourse()], calendar: calendar)
        let date = makeDate(year: 2026, month: 8, day: 17, hour: 12, minute: 0)
        XCTAssertEqual(calculator.nextClass(after: date)?.courseName, "데이터베이스")
    }

    func testAfterLastClassFindsNextScheduledDay() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let date = makeDate(year: 2026, month: 8, day: 17, hour: 22, minute: 0)
        XCTAssertEqual(calculator.nextClass(after: date)?.weekday, .wednesday)
    }

    func testGapDaySkipsToNextClass() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let date = makeDate(year: 2026, month: 8, day: 19, hour: 22, minute: 0)
        XCTAssertEqual(calculator.nextClass(after: date)?.weekday, .monday)
    }

    func testFridayAfterClassFindsNextMonday() throws {
        let mondayOnly = CourseSnapshot(
            id: UUID(),
            name: "컴퓨터구조",
            professor: nil,
            location: nil,
            colorHex: "#4F7DFF",
            schedules: [
                ClassScheduleSnapshot(id: UUID(), weekday: .monday, startTime: TimeOfDay(hour: 9, minute: 0), endTime: TimeOfDay(hour: 10, minute: 15))
            ],
            createdAt: Date()
        )

        let calculator = ScheduleCalculator(courses: [mondayOnly], calendar: calendar)
        let friday = makeDate(year: 2026, month: 8, day: 21, hour: 18, minute: 0)
        XCTAssertEqual(calculator.nextClass(after: friday)?.weekday, .monday)
    }

    func testWeekendScheduleIsIncluded() throws {
        let saturdayCourse = CourseSnapshot(
            id: UUID(),
            name: "창업세미나",
            professor: nil,
            location: nil,
            colorHex: "#2AA889",
            schedules: [
                ClassScheduleSnapshot(id: UUID(), weekday: .saturday, startTime: TimeOfDay(hour: 13, minute: 0), endTime: TimeOfDay(hour: 15, minute: 0))
            ],
            createdAt: Date()
        )

        let calculator = ScheduleCalculator(courses: [saturdayCourse], calendar: calendar)
        let friday = makeDate(year: 2026, month: 8, day: 21, hour: 18, minute: 0)
        XCTAssertEqual(calculator.nextClass(after: friday)?.weekday, .saturday)
    }

    func testCourseWithMultipleDays() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let monday = makeDate(year: 2026, month: 8, day: 17, hour: 0, minute: 0)
        let wednesday = makeDate(year: 2026, month: 8, day: 19, hour: 0, minute: 0)
        XCTAssertEqual(calculator.schedules(for: monday).count, 1)
        XCTAssertEqual(calculator.schedules(for: wednesday).count, 1)
    }

    func testWeekdayScheduleMondayToFridayBuildsWidgetGridData() throws {
        let calculator = ScheduleCalculator(courses: [sampleCourse()], calendar: calendar)
        let tuesday = makeDate(year: 2026, month: 8, day: 18, hour: 9, minute: 0)
        let weekdaySchedule = calculator.weekdayScheduleMondayToFriday(inWeekOf: tuesday)

        XCTAssertEqual(Array(weekdaySchedule.keys).sorted(), Weekday.weekdays)
        XCTAssertEqual(weekdaySchedule[.monday]?.first?.courseName, "자료구조")
        XCTAssertEqual(weekdaySchedule[.wednesday]?.first?.courseName, "자료구조")
        XCTAssertEqual(weekdaySchedule[.friday], [])
        XCTAssertNil(weekdaySchedule[.saturday])
    }

    func testWidgetSnapshotRoundTripPreservesMondayAndFridayCourses() throws {
        let snapshot = widgetPipelineSnapshot()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = TimetableSnapshotStore(overrideContainerURL: directory)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        try store.save(snapshot)
        let loadedSnapshot = store.load(source: "Test")

        XCTAssertEqual(loadedSnapshot.courses.count, 2)
        XCTAssertEqual(loadedSnapshot.scheduledClassCount, 2)
        XCTAssertEqual(loadedSnapshot.courses[0].name, "AI프로젝트")
        XCTAssertEqual(loadedSnapshot.courses[0].schedules[0].weekday, .monday)
        XCTAssertEqual(loadedSnapshot.courses[0].schedules[0].startTime, TimeOfDay(hour: 10, minute: 30))
        XCTAssertEqual(loadedSnapshot.courses[0].schedules[0].endTime, TimeOfDay(hour: 11, minute: 45))
        XCTAssertEqual(loadedSnapshot.courses[1].name, "안녕")
        XCTAssertEqual(loadedSnapshot.courses[1].schedules[0].weekday, .friday)
    }

    func testSmallWidgetNextClassBeforeMondayClass() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let mondayMorning = makeDate(year: 2026, month: 8, day: 17, hour: 9, minute: 0)

        let nextClass = calculator.nextClass(after: mondayMorning)

        XCTAssertEqual(nextClass?.courseName, "AI프로젝트")
        XCTAssertEqual(nextClass?.weekday, .monday)
        XCTAssertEqual(nextClass?.startTime, TimeOfDay(hour: 10, minute: 30))
    }

    func testSmallWidgetNextClassSkipsFromMondayToFriday() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let mondayAfterClass = makeDate(year: 2026, month: 8, day: 17, hour: 12, minute: 0)

        let nextClass = calculator.nextClass(after: mondayAfterClass)

        XCTAssertEqual(nextClass?.courseName, "안녕")
        XCTAssertEqual(nextClass?.weekday, .friday)
        XCTAssertEqual(nextClass?.startTime, TimeOfDay(hour: 10, minute: 30))
    }

    func testSmallWidgetNextClassWrapsFromFridayToNextMonday() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let fridayAfterClass = makeDate(year: 2026, month: 8, day: 21, hour: 12, minute: 0)

        let nextClass = calculator.nextClass(after: fridayAfterClass)

        XCTAssertEqual(nextClass?.courseName, "AI프로젝트")
        XCTAssertEqual(nextClass?.weekday, .monday)
        XCTAssertEqual(nextClass?.startTime, TimeOfDay(hour: 10, minute: 30))
    }

    func testMediumWidgetTodayClassesUseOnlyCurrentWeekday() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let monday = makeDate(year: 2026, month: 8, day: 17, hour: 9, minute: 0)

        let todayClasses = calculator.schedules(for: monday)

        XCTAssertEqual(todayClasses.map(\.courseName), ["AI프로젝트"])
        XCTAssertEqual(todayClasses.first?.weekday, .monday)
    }

    func testLargeWidgetWeekdayGridKeepsMondayAndFridayClasses() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let monday = makeDate(year: 2026, month: 8, day: 17, hour: 9, minute: 0)

        let weekdaySchedule = calculator.weekdayScheduleMondayToFriday(inWeekOf: monday)

        XCTAssertEqual(weekdaySchedule[.monday]?.map(\.courseName), ["AI프로젝트"])
        XCTAssertEqual(weekdaySchedule[.friday]?.map(\.courseName), ["안녕"])
        XCTAssertEqual(weekdaySchedule[.tuesday], [])
        XCTAssertEqual(weekdaySchedule[.wednesday], [])
        XCTAssertEqual(weekdaySchedule[.thursday], [])
    }

    func testTimetableLayoutCalculatorPositionsMondayAndFridayClasses() throws {
        let calculator = ScheduleCalculator(courses: widgetPipelineSnapshot().courses, calendar: calendar)
        let monday = makeDate(year: 2026, month: 8, day: 17, hour: 9, minute: 0)
        let weekdaySchedule = calculator.weekdayScheduleMondayToFriday(inWeekOf: monday)

        let items = TimetableLayoutCalculator.positionedClasses(
            weekdayClasses: weekdaySchedule,
            visibleStartMinutes: 8 * 60,
            visibleEndMinutes: 22 * 60,
            dayWidth: 100,
            gridHeight: 840,
            timeAxisWidth: 50,
            columnInset: 6,
            itemGap: 4,
            minimumItemHeight: 24
        )

        let mondayItem = try XCTUnwrap(items.first { $0.scheduledClass.courseName == "AI프로젝트" })
        let fridayItem = try XCTUnwrap(items.first { $0.scheduledClass.courseName == "안녕" })

        XCTAssertEqual(mondayItem.dayIndex, 0)
        XCTAssertEqual(fridayItem.dayIndex, 4)
        XCTAssertEqual(mondayItem.y, 151, accuracy: 0.01)
        XCTAssertEqual(fridayItem.y, 151, accuracy: 0.01)
        XCTAssertEqual(mondayItem.height, 73, accuracy: 0.01)
    }

    func testScheduleDraftPreservesExistingNonPickerMinute() throws {
        let schedule = ClassSchedule(
            weekday: .monday,
            startTime: TimeOfDay(hour: 10, minute: 30),
            endTime: TimeOfDay(hour: 11, minute: 45)
        )

        let draft = ScheduleDraft.from(schedule: schedule)

        XCTAssertEqual(draft.startTime, TimeOfDay(hour: 10, minute: 30))
        XCTAssertEqual(draft.endTime, TimeOfDay(hour: 11, minute: 45))
    }

    func testScheduleDraftDefaultsAndHourChangesUseWholeHours() throws {
        var draft = ScheduleDraft()

        XCTAssertEqual(draft.startTime, TimeOfDay(hour: 10, minute: 0))
        XCTAssertEqual(draft.endTime, TimeOfDay(hour: 11, minute: 0))

        draft.startDate = ScheduleDraft.date(hour: 10, minute: 30)
        draft.endDate = ScheduleDraft.date(hour: 11, minute: 45)

        draft.startHour = 9
        draft.endHour = 12

        XCTAssertEqual(draft.startTime, TimeOfDay(hour: 9, minute: 0))
        XCTAssertEqual(draft.endTime, TimeOfDay(hour: 12, minute: 0))
    }

    private func sampleCourse() -> CourseSnapshot {
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
        )
    }

    private func databaseCourse() -> CourseSnapshot {
        CourseSnapshot(
            id: UUID(),
            name: "데이터베이스",
            professor: nil,
            location: "IT관 401호",
            colorHex: "#E26D5A",
            schedules: [
                ClassScheduleSnapshot(id: UUID(), weekday: .monday, startTime: TimeOfDay(hour: 13, minute: 0), endTime: TimeOfDay(hour: 14, minute: 15))
            ],
            createdAt: Date()
        )
    }

    private func widgetPipelineSnapshot() -> TimetableSnapshot {
        TimetableSnapshot(
            courses: [
                CourseSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    name: "AI프로젝트",
                    professor: "김교수",
                    location: "공학관 302호",
                    colorHex: "#4F7DFF",
                    schedules: [
                        ClassScheduleSnapshot(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
                            weekday: .monday,
                            startTime: TimeOfDay(hour: 10, minute: 30),
                            endTime: TimeOfDay(hour: 11, minute: 45)
                        )
                    ],
                    createdAt: Date(timeIntervalSinceReferenceDate: 1)
                ),
                CourseSnapshot(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    name: "안녕",
                    professor: nil,
                    location: nil,
                    colorHex: "#E26D5A",
                    schedules: [
                        ClassScheduleSnapshot(
                            id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
                            weekday: .friday,
                            startTime: TimeOfDay(hour: 10, minute: 30),
                            endTime: TimeOfDay(hour: 11, minute: 45)
                        )
                    ],
                    createdAt: Date(timeIntervalSinceReferenceDate: 2)
                )
            ],
            generatedAt: Date(timeIntervalSinceReferenceDate: 3)
        )
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ).date!
    }
}
