import SwiftUI
import WidgetKit

struct ClassboardWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: AppConfiguration.widgetKind, provider: TimetableTimelineProvider()) { entry in
            ClassboardWidgetView(entry: entry)
        }
        .configurationDisplayName("Classboard")
        .description("현재 수업과 다음 수업, 오늘 시간표를 확인합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct ClassboardWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: WidgetEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallTimetableWidgetView(entry: entry)
            case .systemMedium:
                MediumTimetableWidgetView(entry: entry)
            default:
                LargeTimetableWidgetView(entry: entry)
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(URL(string: "classboard://timetable"))
    }
}
