import CoreGraphics
import Foundation

struct PositionedTimetableClass: Identifiable, Hashable {
    var id: String
    var scheduledClass: ScheduledClass
    var dayIndex: Int
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
}

enum TimetableLayoutCalculator {
    static func positionedClasses(
        weekdayClasses: [Weekday: [ScheduledClass]],
        weekdays: [Weekday] = Weekday.weekdays,
        visibleStartMinutes: Int,
        visibleEndMinutes: Int,
        dayWidth: CGFloat,
        gridHeight: CGFloat,
        timeAxisWidth: CGFloat,
        columnInset: CGFloat,
        itemGap: CGFloat,
        minimumItemHeight: CGFloat
    ) -> [PositionedTimetableClass] {
        weekdays.enumerated().flatMap { dayIndex, weekday in
            positionedClasses(
                for: visibleClasses(
                    weekdayClasses[weekday] ?? [],
                    visibleStartMinutes: visibleStartMinutes,
                    visibleEndMinutes: visibleEndMinutes
                ),
                dayIndex: dayIndex,
                dayWidth: dayWidth,
                gridHeight: gridHeight,
                timeAxisWidth: timeAxisWidth,
                columnInset: columnInset,
                itemGap: itemGap,
                minimumItemHeight: minimumItemHeight,
                visibleStartMinutes: visibleStartMinutes,
                visibleEndMinutes: visibleEndMinutes
            )
        }
    }

    static func yOffset(
        for minutes: Int,
        gridHeight: CGFloat,
        visibleStartMinutes: Int,
        visibleEndMinutes: Int
    ) -> CGFloat {
        let clampedMinutes = min(max(minutes, visibleStartMinutes), visibleEndMinutes)
        let ratio = CGFloat(clampedMinutes - visibleStartMinutes) / CGFloat(visibleEndMinutes - visibleStartMinutes)
        return ratio * gridHeight
    }

    private static func visibleClasses(
        _ classes: [ScheduledClass],
        visibleStartMinutes: Int,
        visibleEndMinutes: Int
    ) -> [ScheduledClass] {
        classes.filter { scheduledClass in
            scheduledClass.endTime.minutesSinceMidnight > visibleStartMinutes &&
            scheduledClass.startTime.minutesSinceMidnight < visibleEndMinutes
        }
        .sorted {
            if $0.startTime == $1.startTime {
                return $0.courseName.localizedCompare($1.courseName) == .orderedAscending
            }
            return $0.startTime < $1.startTime
        }
    }

    private static func positionedClasses(
        for classes: [ScheduledClass],
        dayIndex: Int,
        dayWidth: CGFloat,
        gridHeight: CGFloat,
        timeAxisWidth: CGFloat,
        columnInset: CGFloat,
        itemGap: CGFloat,
        minimumItemHeight: CGFloat,
        visibleStartMinutes: Int,
        visibleEndMinutes: Int
    ) -> [PositionedTimetableClass] {
        var result: [PositionedTimetableClass] = []
        var currentGroup: [ScheduledClass] = []
        var currentGroupEnd = visibleStartMinutes

        for scheduledClass in classes {
            let start = max(scheduledClass.startTime.minutesSinceMidnight, visibleStartMinutes)
            let end = min(scheduledClass.endTime.minutesSinceMidnight, visibleEndMinutes)

            if currentGroup.isEmpty || start < currentGroupEnd {
                currentGroup.append(scheduledClass)
                currentGroupEnd = max(currentGroupEnd, end)
            } else {
                result.append(contentsOf: positionedOverlapGroup(
                    currentGroup,
                    dayIndex: dayIndex,
                    dayWidth: dayWidth,
                    gridHeight: gridHeight,
                    timeAxisWidth: timeAxisWidth,
                    columnInset: columnInset,
                    itemGap: itemGap,
                    minimumItemHeight: minimumItemHeight,
                    visibleStartMinutes: visibleStartMinutes,
                    visibleEndMinutes: visibleEndMinutes
                ))
                currentGroup = [scheduledClass]
                currentGroupEnd = end
            }
        }

        if !currentGroup.isEmpty {
            result.append(contentsOf: positionedOverlapGroup(
                currentGroup,
                dayIndex: dayIndex,
                dayWidth: dayWidth,
                gridHeight: gridHeight,
                timeAxisWidth: timeAxisWidth,
                columnInset: columnInset,
                itemGap: itemGap,
                minimumItemHeight: minimumItemHeight,
                visibleStartMinutes: visibleStartMinutes,
                visibleEndMinutes: visibleEndMinutes
            ))
        }

        return result
    }

    private static func positionedOverlapGroup(
        _ group: [ScheduledClass],
        dayIndex: Int,
        dayWidth: CGFloat,
        gridHeight: CGFloat,
        timeAxisWidth: CGFloat,
        columnInset: CGFloat,
        itemGap: CGFloat,
        minimumItemHeight: CGFloat,
        visibleStartMinutes: Int,
        visibleEndMinutes: Int
    ) -> [PositionedTimetableClass] {
        let columnCount = max(1, group.count)
        let availableDayWidth = max(1, dayWidth - columnInset * 2)
        let blockWidth = max(16, (availableDayWidth - CGFloat(columnCount - 1) * itemGap) / CGFloat(columnCount))

        return group.enumerated().map { columnIndex, scheduledClass in
            let start = max(scheduledClass.startTime.minutesSinceMidnight, visibleStartMinutes)
            let end = min(scheduledClass.endTime.minutesSinceMidnight, visibleEndMinutes)
            let top = yOffset(
                for: start,
                gridHeight: gridHeight,
                visibleStartMinutes: visibleStartMinutes,
                visibleEndMinutes: visibleEndMinutes
            )
            let bottom = yOffset(
                for: end,
                gridHeight: gridHeight,
                visibleStartMinutes: visibleStartMinutes,
                visibleEndMinutes: visibleEndMinutes
            )
            let dayX = timeAxisWidth + CGFloat(dayIndex) * dayWidth + columnInset
            let x = dayX + CGFloat(columnIndex) * (blockWidth + itemGap)

            return PositionedTimetableClass(
                id: "\(scheduledClass.id)-\(columnIndex)",
                scheduledClass: scheduledClass,
                dayIndex: dayIndex,
                x: x,
                y: top + 1,
                width: blockWidth,
                height: max(minimumItemHeight, bottom - top - 2)
            )
        }
    }
}
