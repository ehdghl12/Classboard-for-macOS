import SwiftUI

struct SmallTimetableWidgetView: View {
    var entry: WidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if entry.snapshot.isEmpty {
                WidgetEmptyStateView(title: "수업을 추가해", message: "시간표를 만들어보세요.")
            } else if let current = entry.currentClass {
                compactClass(title: "현재 수업", scheduledClass: current)
            } else if let next = entry.nextClass {
                compactClass(title: "다음 수업", scheduledClass: next)
            } else {
                WidgetEmptyStateView(title: "다음 수업 없음", message: "예정된 수업이 없습니다.")
            }
        }
        .padding(14)
    }

    private func compactClass(title: String, scheduledClass: ScheduledClass) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)

            Text(breakableCourseName(scheduledClass.courseName))
                .font(.headline.weight(.semibold))
                .lineLimit(2, reservesSpace: true)
                .lineSpacing(1)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
                .accessibilityLabel(scheduledClass.courseName)

            if let location = scheduledClass.location {
                Text(location)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text("\(scheduledClass.weekday.displayName) \(scheduledClass.startTime.displayText)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func breakableCourseName(_ name: String) -> String {
        var result = ""

        for scalar in name.unicodeScalars {
            result.unicodeScalars.append(scalar)

            if isHangulSyllable(scalar) || isCourseNameBreakPunctuation(scalar) {
                result.append("\u{200B}")
            }
        }

        return result
    }

    private func isHangulSyllable(_ scalar: Unicode.Scalar) -> Bool {
        (0xAC00...0xD7A3).contains(scalar.value)
    }

    private func isCourseNameBreakPunctuation(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x29, 0x2D, 0x2F:
            true
        default:
            false
        }
    }
}
