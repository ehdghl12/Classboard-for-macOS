import SwiftUI

struct CourseCard: View {
    var scheduledClass: ScheduledClass
    var isCurrent: Bool = false
    var compact: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 3 : 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(ColorHelper.color(for: scheduledClass.colorHex))
                    .frame(width: 9, height: 9)
                    .accessibilityHidden(true)

                Text(scheduledClass.courseName)
                    .font(compact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }

            TimeLabel(start: scheduledClass.startTime, end: scheduledClass.endTime)

            if let location = scheduledClass.location {
                Label(location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if !compact, let professor = scheduledClass.professor {
                Label(professor, systemImage: "person")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(compact ? 10 : 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(ColorHelper.color(for: scheduledClass.colorHex))
                .frame(width: 4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var cardBackground: AnyShapeStyle {
        if isCurrent {
            AnyShapeStyle(ColorHelper.color(for: scheduledClass.colorHex).opacity(0.18))
        } else {
            AnyShapeStyle(.quaternary)
        }
    }

    private var accessibilityLabel: String {
        [
            isCurrent ? "현재 수업" : nil,
            scheduledClass.courseName,
            scheduledClass.timeRangeText,
            scheduledClass.location,
            scheduledClass.professor
        ]
        .compactMap { $0 }
        .joined(separator: ", ")
    }
}
