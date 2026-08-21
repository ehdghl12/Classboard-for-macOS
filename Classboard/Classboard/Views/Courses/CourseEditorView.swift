import SwiftData
import SwiftUI

struct CourseEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .forward) private var existingCourses: [Course]

    private let course: Course?

    @State private var name: String
    @State private var professor: String
    @State private var location: String
    @State private var colorHex: String
    @State private var schedules: [ScheduleDraft]
    @State private var errorMessage: String?

    init(course: Course? = nil, defaultColorHex: String = ColorHelper.defaultColor(index: 0)) {
        self.course = course
        _name = State(initialValue: course?.name ?? "")
        _professor = State(initialValue: course?.professor ?? "")
        _location = State(initialValue: course?.location ?? "")
        _colorHex = State(initialValue: course?.colorHex ?? defaultColorHex)
        _schedules = State(initialValue: course?.schedules.map(ScheduleDraft.from).sorted(by: { $0.startTime < $1.startTime }) ?? [ScheduleDraft()])
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 22)
                .padding(.bottom, 14)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    courseFields
                    scheduleSection
                    colorSection
                    validationSection
                }
                .padding(24)
            }

            Divider()

            footer
                .padding(16)
        }
        .frame(width: 560, height: 640)
        .alert("저장할 수 없습니다", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(course == nil ? "수업 추가" : "수업 수정")
                    .font(.title2.bold())
                Text("과목과 하나 이상의 수업 시간을 입력하세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var courseFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("과목 정보")
                .font(.headline)

            TextField("과목명 *", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("교수명", text: $professor)
                .textFieldStyle(.roundedBorder)

            TextField("장소", text: $location)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("수업 시간")
                    .font(.headline)
                Spacer()
                Button {
                    schedules.append(ScheduleDraft())
                } label: {
                    Label("시간 추가", systemImage: "plus")
                }
            }

            VStack(spacing: 8) {
                ForEach($schedules) { $draft in
                    ScheduleRowEditor(
                        draft: $draft,
                        canDelete: schedules.count > 1,
                        onDelete: {
                            schedules.removeAll { $0.id == draft.id }
                        }
                    )
                }
            }
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("색상")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(AppConfiguration.defaultCourseColors, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(ColorHelper.color(for: hex))
                            .frame(width: 24, height: 24)
                            .overlay {
                                if colorHex == hex {
                                    Circle()
                                        .strokeBorder(.primary, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .help(hex)
                    .accessibilityLabel("과목 색상 \(hex)")
                }
            }
        }
    }

    private var validationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(validationMessages, id: \.self) { message in
                Label(message, systemImage: "exclamationmark.circle")
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            if let warning = overlapWarning {
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("취소") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)

            Button(course == nil ? "추가" : "저장") {
                save()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!canSave)
        }
    }

    private var validationMessages: [String] {
        var messages: [String] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            messages.append("과목명을 입력하세요.")
        }

        if schedules.isEmpty {
            messages.append("최소 하나 이상의 수업 시간이 필요합니다.")
        }

        for schedule in schedules where schedule.endTime <= schedule.startTime {
            messages.append("\(schedule.weekday.displayName) 수업의 종료 시간이 시작 시간보다 늦어야 합니다.")
        }

        let duplicateKeys = schedules.map { "\($0.weekday.rawValue)-\($0.startTime.minutesSinceMidnight)-\($0.endTime.minutesSinceMidnight)" }
        if Set(duplicateKeys).count != duplicateKeys.count {
            messages.append("동일한 수업 시간이 중복되어 있습니다.")
        }

        return Array(Set(messages)).sorted()
    }

    private var canSave: Bool {
        validationMessages.isEmpty
    }

    private var overlapWarning: String? {
        let otherCourses = existingCourses.filter { $0.id != course?.id }
        for draft in schedules {
            for otherCourse in otherCourses {
                for otherSchedule in otherCourse.schedules where otherSchedule.weekday == draft.weekday {
                    if draft.startTime < otherSchedule.endTime && otherSchedule.startTime < draft.endTime {
                        return "다른 수업과 시간이 겹칩니다. 저장은 가능합니다."
                    }
                }
            }
        }
        return nil
    }

    private func save() {
        guard canSave else {
            errorMessage = validationMessages.first
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedProfessor = normalizedOptional(professor)
        let trimmedLocation = normalizedOptional(location)
        let newSchedules = schedules.map {
            ClassSchedule(weekday: $0.weekday, startTime: $0.startTime, endTime: $0.endTime)
        }

        if let course {
            for schedule in course.schedules {
                modelContext.delete(schedule)
            }
            course.name = trimmedName
            course.professor = trimmedProfessor
            course.location = trimmedLocation
            course.colorHex = colorHex
            course.schedules = newSchedules
        } else {
            let newCourse = Course(
                name: trimmedName,
                professor: trimmedProfessor,
                location: trimmedLocation,
                colorHex: colorHex,
                schedules: newSchedules
            )
            modelContext.insert(newCourse)
        }

        do {
            try modelContext.save()
            WidgetSyncService.synchronize(modelContext: modelContext, reason: course == nil ? "courseCreate" : "courseUpdate")
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func normalizedOptional(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
