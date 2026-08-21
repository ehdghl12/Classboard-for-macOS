import SwiftUI

struct MediumTimetableWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("오늘 수업")
                .font(.headline)

            if entry.snapshot.isEmpty {
                WidgetEmptyStateView(title: "수업을 추가해", message: "시간표를 만들어보세요.")
            } else if entry.todayClasses.isEmpty {
                WidgetEmptyStateView(title: "오늘 수업 없음", message: "예정된 수업이 없습니다.")
            } else {
                VStack(spacing: 7) {
                    ForEach(entry.todayClasses.prefix(5)) { scheduledClass in
                        classRow(scheduledClass)
                    }

                    if entry.todayClasses.count > 5 {
                        Text("+ \(entry.todayClasses.count - 5)개 더")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }

    private func classRow(_ scheduledClass: ScheduledClass) -> some View {
        let isCurrent = entry.currentClass?.id == scheduledClass.id

        return HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(ColorHelper.color(for: scheduledClass.colorHex))
                .frame(width: 5, height: 26)

            Text(scheduledClass.startTime.displayText)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(scheduledClass.courseName)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                if let location = scheduledClass.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(isCurrent ? ColorHelper.color(for: scheduledClass.colorHex).opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
    }
}
