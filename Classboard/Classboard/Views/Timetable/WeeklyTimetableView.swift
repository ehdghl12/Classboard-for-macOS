import SwiftData
import SwiftUI

struct WeeklyTimetableView: View {
    @Query(sort: \Course.createdAt, order: .forward) private var courses: [Course]

    private let visibleStartMinutes = 8 * 60
    private let visibleEndMinutes = 22 * 60
    private let timeAxisWidth: CGFloat = 58
    private let dayHeaderHeight: CGFloat = 34
    private let hourHeight: CGFloat = 58

    private var snapshot: TimetableSnapshot {
        TimetableService.snapshot(from: courses)
    }

    var body: some View {
        let snapshots = snapshot.courses
        let calculator = ScheduleCalculator(courses: snapshots)
        let weekdayClasses = calculator.weekdayScheduleMondayToFriday(inWeekOf: Date())

        VStack(alignment: .leading, spacing: 18) {
            header

            if snapshots.isEmpty {
                EmptyStateView(
                    title: "시간표가 비어 있습니다",
                    message: "수업 관리에서 첫 수업을 추가해보세요.",
                    systemImage: "calendar.badge.plus"
                )
            } else {
                GeometryReader { proxy in
                    ScrollView(.vertical) {
                        timetableGrid(
                            width: proxy.size.width,
                            weekdayClasses: weekdayClasses
                        )
                        .frame(width: proxy.size.width, height: gridContentHeight + dayHeaderHeight)
                    }
                }
            }
        }
        .padding(24)
        .navigationTitle("시간표")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("주간 시간표")
                .font(.largeTitle.bold())
            Text("등록한 수업을 한눈에 확인합니다.")
                .foregroundStyle(.secondary)
        }
    }

    private var gridContentHeight: CGFloat {
        CGFloat(visibleEndMinutes - visibleStartMinutes) / 60 * hourHeight
    }

    private func timetableGrid(width: CGFloat, weekdayClasses: [Weekday: [ScheduledClass]]) -> some View {
        let gridWidth = max(1, width - timeAxisWidth)
        let dayWidth = gridWidth / CGFloat(Weekday.weekdays.count)
        let positionedClasses = TimetableLayoutCalculator.positionedClasses(
            weekdayClasses: weekdayClasses,
            visibleStartMinutes: visibleStartMinutes,
            visibleEndMinutes: visibleEndMinutes,
            dayWidth: dayWidth,
            gridHeight: gridContentHeight,
            timeAxisWidth: timeAxisWidth,
            columnInset: 6,
            itemGap: 4,
            minimumItemHeight: 24
        )

        return ZStack(alignment: .topLeading) {
            dayHeaders(dayWidth: dayWidth)
                .offset(x: timeAxisWidth)

            gridLines(gridWidth: gridWidth, dayWidth: dayWidth)
                .offset(y: dayHeaderHeight)

            ForEach(positionedClasses) { item in
                classBlock(item)
                    .frame(width: item.width, height: item.height)
                    .offset(x: item.x, y: item.y + dayHeaderHeight)
            }
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.14), lineWidth: 1)
        )
    }

    private func dayHeaders(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Weekday.weekdays) { weekday in
                Text(weekday.displayName)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: dayWidth, height: dayHeaderHeight)
            }
        }
    }

    private func gridLines(gridWidth: CGFloat, dayWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(stride(from: visibleStartMinutes, through: visibleEndMinutes, by: 60)), id: \.self) { minutes in
                let y = yOffset(for: minutes)

                Rectangle()
                    .fill(Color.secondary.opacity(minutes % 120 == 0 ? 0.18 : 0.10))
                    .frame(width: gridWidth, height: 1)
                    .offset(x: timeAxisWidth, y: y)

                Text(timeLabel(for: minutes))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: timeAxisWidth - 10, alignment: .trailing)
                    .offset(x: 0, y: max(0, min(gridContentHeight - 14, y - 7)))
            }

            ForEach(0...Weekday.weekdays.count, id: \.self) { index in
                Rectangle()
                    .fill(Color.secondary.opacity(0.12))
                    .frame(width: 1, height: gridContentHeight)
                    .offset(x: timeAxisWidth + CGFloat(index) * dayWidth)
            }
        }
        .frame(width: gridWidth + timeAxisWidth, height: gridContentHeight, alignment: .topLeading)
    }

    private func classBlock(_ item: PositionedTimetableClass) -> some View {
        let scheduledClass = item.scheduledClass
        let color = ColorHelper.color(for: scheduledClass.colorHex)

        return VStack(alignment: .leading, spacing: 3) {
            Text(scheduledClass.courseName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            if item.height >= 42, let location = scheduledClass.location {
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if item.height >= 60, let professor = scheduledClass.professor {
                Text(professor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if item.height >= 78 {
                Text(scheduledClass.timeRangeText)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.20), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(color.opacity(0.62), lineWidth: 1)
        )
    }

    private func yOffset(for minutes: Int) -> CGFloat {
        TimetableLayoutCalculator.yOffset(
            for: minutes,
            gridHeight: gridContentHeight,
            visibleStartMinutes: visibleStartMinutes,
            visibleEndMinutes: visibleEndMinutes
        )
    }

    private func timeLabel(for minutes: Int) -> String {
        String(format: "%02d:00", minutes / 60)
    }
}
