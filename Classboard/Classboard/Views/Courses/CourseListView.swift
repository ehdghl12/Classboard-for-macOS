import SwiftData
import SwiftUI

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .forward) private var courses: [Course]

    @State private var isPresentingAdd = false
    @State private var editingCourse: Course?
    @State private var deletingCourse: Course?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if courses.isEmpty {
                EmptyStateView(
                    title: "등록된 수업이 없습니다",
                    message: "수업 추가 버튼으로 시간표를 시작하세요.",
                    systemImage: "calendar.badge.plus"
                )
            } else {
                List {
                    ForEach(courses) { course in
                        courseRow(course)
                    }
                }
                .listStyle(.inset)
            }
        }
        .padding(24)
        .navigationTitle("수업 관리")
        .toolbar {
            Button {
                isPresentingAdd = true
            } label: {
                Label("수업 추가", systemImage: "plus")
            }
        }
        .sheet(isPresented: $isPresentingAdd) {
            CourseEditorView(defaultColorHex: ColorHelper.defaultColor(index: courses.count))
        }
        .sheet(item: $editingCourse) { course in
            CourseEditorView(course: course)
        }
        .confirmationDialog(
            "이 과목을 삭제할까요?",
            isPresented: Binding(
                get: { deletingCourse != nil },
                set: { if !$0 { deletingCourse = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                deletePendingCourse()
            }
            Button("취소", role: .cancel) {
                deletingCourse = nil
            }
        } message: {
            Text("삭제하면 이 과목의 모든 수업 시간이 함께 제거됩니다.")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text("수업 관리")
                    .font(.largeTitle.bold())
                Text("과목을 추가하고 여러 요일의 수업 시간을 관리합니다.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                isPresentingAdd = true
            } label: {
                Label("수업 추가", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func courseRow(_ course: Course) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(ColorHelper.color(for: course.colorHex))
                .frame(width: 12, height: 12)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(.headline)

                if let professor = course.professor {
                    Text(professor)
                        .foregroundStyle(.secondary)
                }

                if let location = course.location {
                    Text(location)
                        .foregroundStyle(.secondary)
                }

                Text(scheduleSummary(for: course))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                editingCourse = course
            } label: {
                Image(systemName: "pencil")
            }
            .help("수업 수정")

            Button(role: .destructive) {
                deletingCourse = course
            } label: {
                Image(systemName: "trash")
            }
            .help("수업 삭제")
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private func scheduleSummary(for course: Course) -> String {
        course.schedules
            .sorted {
                if $0.weekday == $1.weekday {
                    return $0.startTime < $1.startTime
                }
                return $0.weekday < $1.weekday
            }
            .map { "\($0.weekday.shortName) \($0.startTime.displayText)-\($0.endTime.displayText)" }
            .joined(separator: ", ")
    }

    private func deletePendingCourse() {
        guard let deletingCourse else { return }
        modelContext.delete(deletingCourse)

        do {
            try modelContext.save()
            WidgetSyncService.synchronize(modelContext: modelContext, reason: "courseDelete")
        } catch {
            assertionFailure("Course deletion failed: \(error.localizedDescription)")
        }

        self.deletingCourse = nil
    }
}
