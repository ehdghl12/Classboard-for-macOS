import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection: SidebarItem? = .timetable

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.timetable) {
                    Label("시간표", systemImage: "calendar")
                }
                NavigationLink(value: SidebarItem.courses) {
                    Label("수업 관리", systemImage: "list.bullet")
                }
            }
            .navigationTitle("Classboard")
        } detail: {
            Group {
                switch selection ?? .timetable {
                case .timetable:
                    WeeklyTimetableView()
                case .courses:
                    CourseListView()
                }
            }
            .frame(minWidth: 760, minHeight: 520)
        }
        .onOpenURL { url in
            switch url.host() {
            case "courses":
                selection = .courses
            default:
                selection = .timetable
            }
        }
        .task {
            WidgetSyncService.synchronize(
                modelContext: modelContext,
                reloadWidget: true,
                reason: "appLaunch",
                preserveExistingSnapshotWhenFetchedEmpty: true
            )
        }
    }
}

private enum SidebarItem: String, CaseIterable, Identifiable {
    case timetable
    case courses

    var id: String { rawValue }
}
