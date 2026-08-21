import SwiftUI

struct LargeTimetableWidgetView: View {
    var entry: WidgetEntry

    private let visibleStartMinutes = 8 * 60
    private let visibleEndMinutes = 20 * 60
    private let timeAxisWidth: CGFloat = 34
    private let dayHeaderHeight: CGFloat = 18

    var body: some View {
        Group {
            if entry.snapshot.isEmpty {
                WidgetEmptyStateView(title: "수업을 추가해", message: "시간표를 만들어보세요.")
            } else {
                GeometryReader { proxy in
                    weeklyGrid(size: proxy.size)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func weeklyGrid(size: CGSize) -> some View {
        let gridWidth = max(1, size.width - timeAxisWidth)
        let gridHeight = max(1, size.height - dayHeaderHeight)
        let dayWidth = gridWidth / CGFloat(Weekday.weekdays.count)
        let positionedClasses = TimetableLayoutCalculator.positionedClasses(
            weekdayClasses: entry.weekdayClasses,
            visibleStartMinutes: visibleStartMinutes,
            visibleEndMinutes: visibleEndMinutes,
            dayWidth: dayWidth,
            gridHeight: gridHeight,
            timeAxisWidth: timeAxisWidth,
            columnInset: 2,
            itemGap: 2,
            minimumItemHeight: 18
        )

        return ZStack(alignment: .topLeading) {
            dayHeaders(dayWidth: dayWidth)
                .offset(x: timeAxisWidth)

            gridLines(gridWidth: gridWidth, gridHeight: gridHeight, dayWidth: dayWidth)
                .offset(y: dayHeaderHeight)

            ForEach(positionedClasses) { item in
                classBlock(item)
                    .frame(width: item.width, height: item.height)
                    .offset(x: item.x, y: item.y + dayHeaderHeight)
            }

            if positionedClasses.isEmpty {
                Text("월-금 수업 없음")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: gridWidth, height: gridHeight)
                    .offset(x: timeAxisWidth, y: dayHeaderHeight)
            }
        }
        .clipped()
    }

    private func dayHeaders(dayWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Weekday.weekdays) { weekday in
                Text(weekday.shortName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: dayWidth, height: dayHeaderHeight)
            }
        }
    }

    private func gridLines(gridWidth: CGFloat, gridHeight: CGFloat, dayWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(stride(from: visibleStartMinutes, through: visibleEndMinutes, by: 120)), id: \.self) { minutes in
                let y = yOffset(for: minutes, gridHeight: gridHeight)

                Rectangle()
                    .fill(Color.secondary.opacity(0.14))
                    .frame(width: gridWidth, height: 1)
                    .offset(x: timeAxisWidth, y: y)

                Text(timeLabel(for: minutes))
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: timeAxisWidth - 4, alignment: .trailing)
                    .offset(x: 0, y: max(0, min(gridHeight - 10, y - 5)))
            }

            ForEach(0...Weekday.weekdays.count, id: \.self) { index in
                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 1, height: gridHeight)
                    .offset(x: timeAxisWidth + CGFloat(index) * dayWidth)
            }
        }
        .frame(width: gridWidth + timeAxisWidth, height: gridHeight, alignment: .topLeading)
    }

    private func classBlock(_ item: PositionedTimetableClass) -> some View {
        let scheduledClass = item.scheduledClass
        let color = ColorHelper.color(for: scheduledClass.colorHex)

        return VStack(alignment: .leading, spacing: 0) {
            Text(scheduledClass.courseName)
                .font(.caption2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.24), in: RoundedRectangle(cornerRadius: 5))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(color.opacity(0.55), lineWidth: 1)
        )
    }

    private func yOffset(for minutes: Int, gridHeight: CGFloat) -> CGFloat {
        TimetableLayoutCalculator.yOffset(
            for: minutes,
            gridHeight: gridHeight,
            visibleStartMinutes: visibleStartMinutes,
            visibleEndMinutes: visibleEndMinutes
        )
    }

    private func timeLabel(for minutes: Int) -> String {
        String(format: "%02d:00", minutes / 60)
    }
}
